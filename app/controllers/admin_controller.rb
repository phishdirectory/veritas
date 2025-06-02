# app/controllers/admin_controller.rb
# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  layout "admin"

  def index
    # Admin dashboard stats
    @services_count = Service.count
    @users_count = User.count
    @active_keys_count = Service::Key.active.count
  end

  def services
    @services = Service.order(created_at: :desc)
  end

  def users
    @users = User.order(created_at: :desc)
  end

end
