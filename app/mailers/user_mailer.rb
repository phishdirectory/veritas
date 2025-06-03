# frozen_string_literal: true

class UserMailer < ApplicationMailer
  default from: email_address_with_name("no-reply@transactional.phish.directory", "Phish Directory"), reply_to: email_address_with_name("support@phish.directory", "phish.directory Support")

  def welcome
    @user = params[:user]
    mail(to: email_address_with_name(@user.email, @user.name),
         from: email_address_with_name("welcome@transactional.phish.directory", "Phish Directory"),
         subject: env_subject("Welcome to Phish Directory!"))
  end

  def login
    @user = params[:user]
    @ip_address = params[:ip_address]
    @timestamp = params[:timestamp]
    @user_agent = params[:user_agent]
    mail(to: email_address_with_name(@user.email, @user.name),
         from: email_address_with_name("logins@transactional.phish.directory", "Phish Directory Logins"),
         subject: env_subject("New Sign-in Detected - Phish Directory"))
  end

end
