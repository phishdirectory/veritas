# frozen_string_literal: true

class EmailConfirmationsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show, :confirm, :resend]
  before_action :authenticate_user_without_email_verification!, only: [:show, :resend]

  def show
    # Show the confirmation required page
    @user = current_user
    redirect_to root_path if @user&.email_verified?
  end

  def confirm
    @user = User.find_by(confirmation_token: params[:token])

    if @user.nil?
      flash[:alert] = "Invalid confirmation token."
    elsif @user.email_verified?
      flash[:notice] = "Your email has already been confirmed."
    else
      @user.verify_email
      # Send welcome email, invite to slack, and notify ops now that email is confirmed
      WelcomeEmailJob.perform_later(@user)
      InviteToSlackJob.perform_later(@user.email)
      NotifyOpsOnNewUserJob.perform_later(@user)
      flash[:notice] = "Your email has been successfully confirmed! You can now log in."
    end
    redirect_to login_path
  end

  def resend
    @user = current_user

    if @user.email_verified?
      respond_to do |format|
        format.html do
          flash[:notice] = "Your email is already confirmed."
          redirect_to root_path
        end
        format.turbo_stream do
          flash.now[:notice] = "Your email is already confirmed."
          redirect_to root_path
        end
      end
    elsif @user.confirmation_period_valid?
      time_left = 5.minutes - (Time.current - @user.confirmation_sent_at)
      minutes_left = (time_left / 60).ceil

      respond_to do |format|
        format.html do
          flash[:alert] = "Please wait #{minutes_left} minutes before requesting another confirmation email."
          redirect_to email_confirmation_path
        end
        format.turbo_stream do
          flash.now[:alert] = "Please wait #{minutes_left} minutes before requesting another confirmation email."
          render turbo_stream: turbo_stream.replace("resend_section", partial: "resend_section", locals: { user: @user })
        end
      end
    else
      @user.send_confirmation_email

      respond_to do |format|
        format.html do
          flash[:notice] = "A new confirmation email has been sent to your email address."
          redirect_to email_confirmation_path
        end
        format.turbo_stream do
          flash.now[:notice] = "A new confirmation email has been sent to your email address."
          render turbo_stream: turbo_stream.replace("resend_section", partial: "resend_section", locals: { user: @user })
        end
      end
    end
  end

end
