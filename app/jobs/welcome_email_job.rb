# frozen_string_literal: true

class WelcomeEmailJob < ApplicationJob
  queue_as :default

  def perform(*args)
    UserMailer.welcome(user: args[0]).deliver_later
  end

end
