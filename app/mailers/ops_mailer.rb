# frozen_string_literal: true

class OpsMailer < ApplicationMailer
  default from: email_address_with_name("ops@transactional.phish.directory", "[T] Phish Directory Ops")

  def failed_slack_invite
    @user = params[:user]
    @error = params[:error]
    mail(to: "ops@phish.directory",
         subject: env_subject("Failed to invite #{user.email} to Slack"))
  end

  def new_user
    @user = params[:user]
    mail(to: "ops@phish.directory",
         subject: env_subject("New User - Phish Directory"))
  end

end
