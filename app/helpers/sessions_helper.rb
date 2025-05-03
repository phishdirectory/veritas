# frozen_string_literal: true

module SessionsHelper
  SESSION_DURATION_OPTIONS = {
    "1 hour"  => 1.hour.to_i,
    "1 day"   => 1.day.to_i,
    "3 days"  => 3.days.to_i,
    "7 days"  => 7.days.to_i,
    "14 days" => 14.days.to_i,
    "30 days" => 30.days.to_i
  }.freeze

  # app/helpers/sessions_helper.rb
  def sign_in(user:, impersonate: false, fingerprint_info: {})
    # Generate a secure random token
    session_token = SecureRandom.urlsafe_base64(64)

    # Get the impersonator if this is an impersonation
    impersonated_by = impersonate ? current_user : nil

    # Set expiration time based on user preferences
    expiration_at = Time.current + user.session_duration_seconds.seconds

    # Create the session in the database
    session = User::Session.create!(
      user: user,
      impersonated_by: impersonated_by,
      session_token: session_token,
      expiration_at: expiration_at,
      fingerprint: fingerprint_info[:fingerprint],
      device_info: fingerprint_info[:device_info],
      os_info: fingerprint_info[:os_info],
      timezone: fingerprint_info[:timezone],
      ip: fingerprint_info[:ip]
    )

    # Set an encrypted cookie with the session token
    cookies.encrypted[:session_token] = {
      value: session_token,
      expires: expiration_at,
      httponly: true,
      secure: Rails.env.production?
    }

    # Update the current user
    self.current_user = user

    # Return the session
    session
  end

  def impersonate_user(user)
    sign_out
    sign_in(user:, impersonate: true)
  end

  def unimpersonate_user
    curses = current_session
    sign_out
    sign_in(user: curses.impersonated_by)
  end

  def require_login
    return if current_user

    store_location
    flash[:alert] = "Please log in to access this page."
    redirect_to login_path

  end

  def store_location
    session[:return_to] = request.original_url if request.get?
  end

  def redirect_back_or(default)
    redirect_to(session[:return_to] || default)
    session.delete(:return_to)
  end

  # Detect if a session is idle for too long
  def session_timeout
    return unless current_user && current_session

    idle_time = 30.minutes

    if current_session.last_seen_at && current_session.last_seen_at < idle_time.ago
      sign_out
      flash[:alert] = "Your session has expired due to inactivity. Please sign in again."
      redirect_to login_path
    else
      current_session.touch_last_seen_at
    end
  end

  def signed_in?
    !current_user.nil?
  end

  def auditor_signed_in?
    signed_in? && current_user&.auditor?
  end

  def admin_signed_in?
    signed_in? && current_user&.admin?
  end

  def superadmin_signed_in?
    signed_in? &&
      current_user&.superadmin? &&
      !current_session&.impersonated?
  end

  def current_user=(user)
    @current_user = user # rubocop:disable Rails/HelperInstanceVariable
  end

  def current_user
    @current_user ||= current_session&.user
  end

  def current_session
    return @current_session if defined?(@current_session) # rubocop:disable Rails/HelperInstanceVariable

    session_token = cookies.encrypted[:session_token]

    return nil if session_token.nil?

    # Find a valid session (not expired) using the session token
    @current_session = UserSession.not_expired.find_by(session_token:) # rubocop:disable Rails/HelperInstanceVariable
  end

  def signed_in_user
    return if signed_in?

    if request.fullpath == "/"
      redirect_to auth_users_path
    else
      redirect_to auth_users_path(return_to: request.original_url)
    end

  end

  def signed_in_admin
    return if auditor_signed_in?

    redirect_to auth_users_path, flash: { error: "You’ll need to sign in as an admin." }

  end

  def sign_out
    current_user
      &.user_sessions
      &.find_by(session_token: cookies.encrypted[:session_token])
      &.update(signed_out_at: Time.now, expiration_at: Time.now)

    cookies.delete(:session_token)
    self.current_user = nil
  end

  def sign_out_of_all_sessions(user = current_user)
    # Destroy all the sessions except the current session
    user
      &.user_sessions
      &.where&.not(id: current_session.id)
      &.update_all(signed_out_at: Time.now, expiration_at: Time.now)
  end
end
