# frozen_string_literal: true

class Admin::BaseController < ApplicationController
  include EnsureEnabled

  before_action :authenticate_user!
  before_action :require_admin
  before_action :ensure_ui_enabled_for_admin


  layout "admin"

  private

  def require_admin
    return if current_user&.admin?

    redirect_to login_path, alert: "You are not authorized to access this page"
  end

  def ensure_ui_enabled_for_admin
    # For stop_impersonating action, check the admin user instead of the impersonated user
    if action_name == "stop_impersonating" && impersonating?
      admin = admin_user
      ensure_enabled!(:ui, actor: admin) if admin
    else
      ensure_enabled!(:ui, actor: current_user)
    end
  end

end
