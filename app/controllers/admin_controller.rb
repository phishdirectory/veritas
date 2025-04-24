# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :authenticate_user

  def index
    # Render the admin dashboard
  end

  private

  def authenticate_user
    redirect_to login_path unless current_user
  end

  def require_admin
    redirect_to root_path, alert: "Access denied." unless current_user&.admin?
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  helper_method :current_user
  def admin_user?
    current_user&.admin?
  end

end
