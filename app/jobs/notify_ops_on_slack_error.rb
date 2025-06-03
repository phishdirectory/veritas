# frozen_string_literal: true

class NotifyOpsOnSlackErrorJob < ApplicationJob
  queue_as :priority

  def perform(*args)
    OpsMailer.failed_slack_invite(user: args[0], error: args[1]).deliver_later
  end

end
