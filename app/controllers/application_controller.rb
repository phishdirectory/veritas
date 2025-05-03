# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include SessionsHelper

  before_action :session_timeout, if: -> { current_user }

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  # Track papertrail edits to specific users
  before_action :set_paper_trail_whodunnit

  # before_action do
  #   # Disallow indexing
  # response.set_header("X-Robots-Tag", "noindex")
  # end

  # # Enable Rack::MiniProfiler for admins
  before_action do
    if current_user&.admin?
      Rack::MiniProfiler.authorize_request
    end
  end


  helper_method :current_user

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def find_current_auditor
    current_user if current_user&.superadmin?
  end


  def user_not_authorized
    flash[:error] = "You are not authorized to perform this action."
    if current_user || !request.get?
      redirect_to root_path
    else
      redirect_to auth_users_path(return_to: request.url)
    end
  end

  def not_found
    raise ActionController::RoutingError, "Not Found"
  end

  def confetti!(emojis: nil)
    flash[:confetti] = true
    flash[:confetti_emojis] = emojis.join(",") if emojis
  end

  def authenticate_user
    redirect_to login_path unless current_user
  end

end
