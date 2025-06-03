# frozen_string_literal: true

class NotifyOpsOnNewUserJob < ApplicationJob
  queue_as :default

  def perform(*args)
    OpsMailer.new_user.with(user: args[0]).deliver_later
  end

end
