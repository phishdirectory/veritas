# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  include Rails.application.routes.url_helpers
  has_history
  utm_params
  default from: "no-reply@transactional.phish.directory"
  layout "mailer"

  def env_subject(base_subject)
    Rails.env.production? ? base_subject : "[#{Rails.env.upcase}] #{base_subject}"
  end


end
