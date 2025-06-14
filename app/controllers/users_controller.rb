# frozen_string_literal: true

# app/controllers/users_controller.rb
class UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create, :username_conflict]

  layout "sessions", only: [:new]
  def new
    redirect_to root_path if current_user
    @user = User.new
  end

  def create
    begin
      @user = User.new(sanitized_user_params)
    rescue ActiveRecord::RecordInvalid => e
      @user = e.record
      render :new, status: :unprocessable_entity
      return
    end

    if @user.save
      redirect_to email_confirmation_path, notice: "Account created! Please check your email to verify your account."
    else
      # Check if this is a username conflict error
      if @user.errors[:base]&.any? { |message| message.include?("snafu") }
        redirect_to username_conflict_path
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  def username_conflict
    render "errors/username_conflict", layout: false
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    begin
      # Handle cropped image data if present
      if params[:user][:cropped_image_data].present?
        process_cropped_image(params[:user][:cropped_image_data])
      end

      if @user.update(sanitized_user_params.except(:cropped_image_data))
        redirect_to root_path, notice: "Account successfully updated!"
      else
        render :edit, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordInvalid => e
      @user = e.record
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy_profile_photo
    @user = current_user
    if @user.profile_photo.attached?
      @user.profile_photo.purge
      redirect_to edit_profile_path, notice: "Profile photo removed successfully!"
    else
      redirect_to edit_profile_path, alert: "No profile photo to remove."
    end
  end

  private

  def sanitize_input(input, options = {})
    return nil if input.nil?

    original_input = input.to_s
    sanitized = original_input.strip

    # Check for SQL injection patterns
    sql_injection_patterns = [
      /(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION)\b)/i,
      /(--|\/\*|\*\/|;)/,
      /('.*'|".*")/,
      /(\bOR\b|\bAND\b).*[=<>]/i
    ]

    if sql_injection_patterns.any? { |pattern| sanitized.match?(pattern) }
      notify_security_incident(
        email: options[:email],
        input_type: options[:field_name] || "unknown",
        malicious_input: original_input
      )
      raise SecurityError, "Potentially malicious input detected"
    end

    # Remove potentially dangerous characters that could be used for XSS or injection
    sanitized = sanitized.gsub(/[<>'"&]/, {
                                 "<" => "&lt;",
                                 ">" => "&gt;",
                                 "'" => "&#39;",
                                 '"' => "&quot;",
                                 "&" => "&amp;"
                               })

    # Limit length to prevent buffer overflow attacks
    max_length = options[:max_length] || 255
    sanitized.truncate(max_length)
  end

  def sanitize_password(password, options = {})
    return nil if password.nil?

    original_password = password.to_s

    # Check for SQL injection patterns in password
    sql_injection_patterns = [
      /(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION)\b)/i,
      /(--|\/\*|\*\/)/,
      /(\bOR\b|\bAND\b).*[=<>]/i
    ]

    if sql_injection_patterns.any? { |pattern| original_password.match?(pattern) }
      notify_security_incident(
        email: options[:email],
        input_type: "password",
        malicious_input: "[REDACTED - PASSWORD FIELD]"
      )
      raise SecurityError, "Invalid password format"
    end

    # Don't modify password content but check length
    if original_password.length > 255
      notify_security_incident(
        email: options[:email],
        input_type: "password",
        malicious_input: "[REDACTED - OVERSIZED PASSWORD]"
      )
      raise SecurityError, "Password too long"
    end

    original_password
  end

  def notify_security_incident(email:, input_type:, malicious_input:)
    NotifyOpsOnSecurityIncidentJob.perform_later(
      email: email,
      input_type: input_type,
      malicious_input: malicious_input,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
  end

  def sanitized_user_params
    permitted_params = params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation, :profile_photo, :cropped_image_data)
    user_email = permitted_params[:email]

    begin
      # Sanitize text inputs and password fields separately
      sanitized_params = {}

      permitted_params.each do |key, value|
        if value.is_a?(String)
          case key.to_s
          when "password", "password_confirmation"
            sanitized_params[key] = sanitize_password(value, email: user_email)
          else
            sanitized_params[key] = sanitize_input(value, email: user_email, field_name: key.to_s)
          end
        else
          # Handle file uploads and other non-string parameters
          sanitized_params[key] = value
        end
      end

      # Special handling for email - ensure it's properly formatted after sanitization
      if sanitized_params[:email].present?
        sanitized_params[:email] = sanitized_params[:email].downcase.strip
      end

      sanitized_params
    rescue SecurityError => e
      # Add validation error to user instance
      @user ||= User.new
      @user.errors.add(:base, "Invalid input: #{e.message}")
      raise ActiveRecord::RecordInvalid.new(@user)
    end
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
  end

  def process_cropped_image(base64_data)
    # Remove the data:image/jpeg;base64, prefix
    image_data = base64_data.split(",")[1]
    return if image_data.blank?

    # Decode base64 data
    decoded_image = Base64.decode64(image_data)

    # Create a temporary file
    temp_file = Tempfile.new(["cropped_image", ".jpg"])
    temp_file.binmode
    temp_file.write(decoded_image)
    temp_file.rewind

    # Attach the cropped image
    @user.profile_photo.attach(
      io: temp_file,
      filename: "profile_photo_#{@user.pd_id}.jpg",
      content_type: "image/jpeg"
    )

    temp_file.close
    temp_file.unlink
  end

end
