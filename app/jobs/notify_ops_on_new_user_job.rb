# frozen_string_literal: true

class NotifyOpsOnNewUserJob < ApplicationJob
  queue_as :default

  def perform(*args)
    OpsMailer.with(user: args[0]).new_user.deliver_later
  end

end
