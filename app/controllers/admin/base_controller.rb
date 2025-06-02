# frozen_string_literal: true

class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  layout "admin"

  private

  def require_admin
    return if current_user&.admin?

    redirect_to login_path, alert: "You are not authorized to access this page"
  end
end