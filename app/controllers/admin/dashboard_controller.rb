# frozen_string_literal: true

class Admin::DashboardController < Admin::BaseController
  def index
    # Admin dashboard stats
    @services_count = Service.count
    @users_count = User.count
    @admin_count = User.admin.count
  end

end
