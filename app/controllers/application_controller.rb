# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  # Track papertrail edits to specific users
  before_action :set_paper_trail_whodunnit

  # update the current session's last_seen_at
  # before_action { current_session&.touch_last_seen_at }

  before_action do
    # Disallow indexing
    response.set_header("X-Robots-Tag", "noindex")
  end

  # # Enable Rack::MiniProfiler for admins
  # before_action do
  #   if current_user&.admin?
  #     Rack::MiniProfiler.authorize_request
  #   end
  # end

  def find_current_auditor
    current_user
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

end
