# frozen_string_literal: true

class MagicLinkJob < ApplicationJob
  queue_as :default

  def perform(user)
    MagicLinkMailer.login_link(user).deliver_now
  end
end