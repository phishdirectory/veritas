# frozen_string_literal: true

class EmailConfirmationJob < ApplicationJob
  queue_as :default

  def perform(user)
    UserMailer.email_confirmation(user).deliver_now
  end

end
