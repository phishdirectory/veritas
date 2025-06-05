# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :authenticate_user!

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

  def impersonating?
    session[:admin_id].present?
  end

  def admin_user
    @admin_user ||= User.find_by(id: session[:admin_id]) if session[:admin_id]
  end

  def authenticate_user!
    return if current_user

    respond_to do |format|
      format.html do
        session[:return_to] = request.fullpath unless request.xhr?
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

  def sign_in(user:)
    session[:user_id] = user.id
  end

  helper_method :current_user, :impersonating?, :admin_user

  # Track papertrail edits to specific users
  before_action :set_paper_trail_whodunnit


end
