# frozen_string_literal: true

class Admin::DashboardController < Admin::BaseController
  def index
    # Admin dashboard stats
    @services_count = Service.count
    @users_count = User.count
    @active_keys_count = Service::Key.active.count
    @webhooks_count = Service::Webhook.count
  end

end
