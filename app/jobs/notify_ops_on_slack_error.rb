# frozen_string_literal: true

class NotifyOpsOnSlackErrorJob < ApplicationJob
  queue_as :critical

  def perform(*args)
    OpsMailer.with(user: args[0], error: args[1]).failed_slack_invite.deliver_later
  end

end
