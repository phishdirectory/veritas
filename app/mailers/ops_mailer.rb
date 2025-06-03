# frozen_string_literal: true

class OpsMailer < ApplicationMailer
  default from: email_address_with_name("ops@transactional.phish.directory", "[T] Phish Directory Ops")

  def failed_slack_invite
    @user = params[:user]
    @error = params[:error]
    mail(to: "ops@phish.directory",
         subject: env_subject("[!IMPORTANT] Failed to invite #{user.email} to Slack"))
  end

  def new_user
    @user = params[:user]
    mail(to: "ops@phish.directory",
         subject: env_subject("New User!"))
  end

  def username_fail
    @email = params[:email]
    @desired_username = params[:desired_username]
    @existing_user = User.find_by(username: @desired_username)

    # If we can't find the existing user, check all users with similar usernames for debugging
    if @existing_user.nil?
      @similar_users = User.where("username ILIKE ?", "%#{@desired_username}%").limit(5)
      Rails.logger.error "Username conflict reported for '#{@desired_username}' but no user found. Similar usernames: #{@similar_users.pluck(:username)}"
    end

    mail(to: "ops@phish.directory",
         subject: env_subject("[!IMPORTANT] Username Conflict"))
  end

end
