# frozen_string_literal: true

class UsernameFailJob < ApplicationJob
  queue_as :priority

  def perform(*args)
    OpsMailer.with(user: args[0]).username_fail.deliver_later
  end

end
