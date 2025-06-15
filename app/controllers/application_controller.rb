# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :track_user_session

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  # before_action do
  #   # Disallow indexing
  # response.set_header("X-Robots-Tag", "noindex")
  # end

  def find_current_auditor
    current_user if current_user&.superadmin?
  end

  def not_found
    raise ActionController::RoutingError, "Not Found"
  end

  def confetti!(emojis: nil)
    flash[:confetti] = true
    flash[:confetti_emojis] = emojis.join(",") if emojis
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def current_user_session
    return @current_user_session if defined?(@current_user_session)

    @current_user_session = if current_user && session.id
                              current_user.user_sessions.find_by(session_token: session.id.to_s)
                            end
  end

  def impersonating?
    session[:admin_id].present?
  end

  def admin_user
    @admin_user ||= User.find_by(id: session[:admin_id]) if session[:admin_id]
  end

  def authenticate_user!
    unless current_user
      respond_to do |format|
        format.html do
          flash[:alert] = "You need to sign in before continuing"
          redirect_to "/login"
        end
        format.json { render json: { error: "You need to sign in before continuing" }, status: :unauthorized }
      end
      return
    end

    return if current_user.email_verified?

    respond_to do |format|
      format.html do
        flash[:alert] = "Please verify your email address before continuing"
        redirect_to email_confirmation_path
      end
      format.json { render json: { error: "Email verification required", redirect_to: email_confirmation_path }, status: :forbidden }
    end

  end

  def authenticate_user_without_email_verification!
    return if current_user

    respond_to do |format|
      format.html do
        flash[:alert] = "You need to sign in before continuing"
        redirect_to "/login"
      end
      format.json { render json: { error: "You need to sign in before continuing" }, status: :unauthorized }
    end
  end

  def require_admin
    return if current_user&.admin?

    render json: { error: "You are not authorized to perform this action" }, status: :forbidden

  end

  def sign_in(user:, fingerprint_info: {})
    session[:user_id] = user.id

    # Create or update user session with fingerprint info
    user_session = user.user_sessions.create!(
      session_token: session.id.to_s,
      expiration_at: 30.days.from_now,
      fingerprint: fingerprint_info[:fingerprint],
      device_info: fingerprint_info[:device_info],
      os_info: fingerprint_info[:os_info],
      timezone: fingerprint_info[:timezone],
      ip: fingerprint_info[:ip] || request.remote_ip,
      last_seen_at: Time.zone.now
    )

    ahoy.authenticate(user)
    user_session
  end

  def track_user_session
    return unless current_user_session

    current_user_session.touch_last_seen_at
  end

  def sign_out
    current_user_session&.update(signed_out_at: Time.current, expiration_at: Time.current)
    reset_session
  end

  def sign_out_of_all_sessions
    return unless current_user

    current_user.user_sessions.not_expired.each do |session|
      session.update!(signed_out_at: Time.current, expiration_at: Time.current)
    end
    reset_session
  end

  helper_method :current_user, :impersonating?, :admin_user

  # Track papertrail edits to specific users
  before_action :set_paper_trail_whodunnit


end
