# frozen_string_literal: true

class AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:login, :new_session, :oauth_login]

  layout "sessions", only: [:new_session, :oauth_login]

  def new_session
    redirect_to root_path if current_user
    @user = User.new
  end

  def oauth_login
    redirect_to root_path if current_user
    
    # Check if this is a legitimate OAuth flow
    client_id = session[:oauth_client_id] || params[:client_id]
    if client_id.blank?
      # No client_id means this isn't part of an OAuth flow
      redirect_to login_path
      return
    end
    
    @user = User.new
    
    # Get OAuth client information
    @oauth_client_name = nil
    oauth_app = Doorkeeper::Application.find_by(uid: client_id)
    if oauth_app
      @oauth_client_name = oauth_app.name
    else
      # Invalid client_id, redirect to regular login
      redirect_to login_path
      return
    end
  end

  def login
    user_email = params.dig(:user, :email)
    begin
      email = sanitize_input(user_email, email: user_email, field_name: "email")
      password = sanitize_password(params.dig(:user, :password), email: user_email)
    rescue SecurityError => e
      handle_login_error("Invalid input: #{e.message}", user_email)
      return
    end

    if email.blank? || password.blank?
      handle_login_error("Email and password are required", email)
      return
    end

    user = User.find_by(email: email&.downcase)

    if user.nil?
      handle_login_error("No account found with this email", email)
    elsif !user.authenticate(password)
      handle_login_error("Incorrect password", email)
    else
      session[:user_id] = user.id

      if user.email_verified?
        respond_to do |format|
          format.html { redirect_to root_path, notice: "Logged in successfully" }
          format.json { render json: { user: user.as_json(except: :password_digest) } }
        end
      else
        respond_to do |format|
          format.html { redirect_to email_confirmation_path, notice: "Please confirm your email address to continue" }
          format.json { render json: { message: "Email confirmation required", redirect_to: email_confirmation_path }, status: :forbidden }
        end
      end
    end
  end

  def logout
    if session[:admin_id]
      original_admin = User.find(session[:admin_id])
      session[:user_id] = session[:admin_id]
      session.delete(:admin_id)
      respond_to do |format|
        format.html { redirect_to admin_users_path, notice: "Returned to admin account" }
        format.json { render json: { message: "Returned to admin account", user: original_admin.as_json(except: :password_digest) } }
      end
    else
      session.delete(:user_id)
      respond_to do |format|
        format.html { redirect_to login_path, notice: "Logged out successfully" }
        format.json { render json: { message: "Logged out successfully" } }
      end
    end
  end

  def me
    respond_to do |format|
      format.html { render :me }
      format.json { render json: { user: current_user.as_json(except: :password_digest) } }
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

  def handle_login_error(message, email)
    respond_to do |format|
      format.turbo_stream do
        flash.now[:alert] = message
        @user = User.new(email: email)
        render turbo_stream: [
          turbo_stream.update("flash", partial: "shared/flash"),
          turbo_stream.update("login_form", partial: "auth/login_form", locals: { user: @user })
        ], status: :unprocessable_entity
      end
      format.html do
        flash.now[:alert] = message
        @user = User.new(email: email)
        render :new_session, status: :unprocessable_entity
      end
      format.json { render json: { error: message }, status: :unauthorized }
    end
  end

  def user_params
    params.expect(user: [:email, :username, :password, :password_confirmation,
                         :first_name, :last_name, :role])
  end

end
