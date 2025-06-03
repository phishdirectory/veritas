# frozen_string_literal: true

class InviteToSlackJob < ApplicationJob
  queue_as :default

  def perform(*args)
    email = args[0]
    SlackService.invite(email)
  end

end
