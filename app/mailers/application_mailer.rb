# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  has_history
  default from: "noreply@phish.directory"
  layout "mailer"

end
