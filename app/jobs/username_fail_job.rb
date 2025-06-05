# frozen_string_literal: true

class UsernameFailJob < ApplicationJob
  queue_as :critical

  def perform(**params)
    Rails.logger.info "UsernameFailJob params: #{params.inspect}"
    email = params[:email]
    desired_username = params[:desired_username]

    # Handle case where email might be a hash (serialization issue)
    if email.is_a?(Hash)
      email = email[:email] || email["email"]
    end

    OpsMailer.with(email: email, desired_username: desired_username).username_fail.deliver_later
  end

end
