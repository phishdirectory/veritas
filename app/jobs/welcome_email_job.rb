# frozen_string_literal: true

class WelcomeEmailJob < ApplicationJob
  queue_as :default

  def perform(*args)
    UserMailer.with(user: args[0]).welcome.deliver_later
  end

end
