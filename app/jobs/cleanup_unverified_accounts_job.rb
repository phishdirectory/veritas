# frozen_string_literal: true

class CleanupUnverifiedAccountsJob < ApplicationJob
  queue_as :default

  def perform
    # Find users who haven't verified their email and were created more than 3 days ago
    unverified_users = User.where(email_verified: false)
                           .where("created_at < ?", 3.days.ago)

    count = unverified_users.count

    if count > 0
      Rails.logger.info "Cleaning up #{count} unverified accounts older than 3 days"
      unverified_users.destroy_all
      Rails.logger.info "Cleanup complete: #{count} unverified accounts deleted"
    else
      Rails.logger.info "No unverified accounts older than 3 days found"
    end
  end

end
