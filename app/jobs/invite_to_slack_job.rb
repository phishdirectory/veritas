# frozen_string_literal: true

class InviteToSlackJob < ApplicationJob
  queue_as :default

  def perform(*args)
    email = args[0]
    if Rails.env.production?
      SlackService.invite(email)
    else
      Rails.logger.info("Would have invited #{email} to Slack")
    end
  end

end
