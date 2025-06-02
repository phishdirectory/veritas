# frozen_string_literal: true

class AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:login, :new_session]

  def new_session
    redirect_to root_path if current_user
    @user = User.new
  end

  def login
    email = params.dig(:user, :email)
    password = params.dig(:user, :password)

    if email.blank? || password.blank?
      handle_login_error("Email and password are required", email)
      return
    end

    user = User.find_by(email: email&.downcase)

    if user.nil?
      handle_login_error("No account found with this email", email)
    elsif !user.authenticate(password)
      handle_login_error("Incorrect password", email)
    else
      session[:user_id] = user.id
      respond_to do |format|
        format.html { redirect_to root_path, notice: "Logged in successfully" }
        format.json { render json: { user: user.as_json(except: :password_digest) } }
      end
    end
  end

  def logout
    if session[:admin_id]
      original_admin = User.find(session[:admin_id])
      session[:user_id] = session[:admin_id]
      session.delete(:admin_id)
      respond_to do |format|
        format.html { redirect_to admin_users_path, notice: "Returned to admin account" }
        format.json { render json: { message: "Returned to admin account", user: original_admin.as_json(except: :password_digest) } }
      end
    else
      session.delete(:user_id)
      respond_to do |format|
        format.html { redirect_to login_path, notice: "Logged out successfully" }
        format.json { render json: { message: "Logged out successfully" } }
      end
    end
  end

  def me
    respond_to do |format|
      format.html { render :me }
      format.json { render json: { user: current_user.as_json(except: :password_digest) } }
    end
  end

  private

  def handle_login_error(message, email)
    respond_to do |format|
      format.turbo_stream do
        flash.now[:alert] = message
        @user = User.new(email: email)
        render turbo_stream: [
          turbo_stream.update("flash", partial: "shared/flash"),
          turbo_stream.update("login_form", partial: "auth/login_form", locals: { user: @user })
        ], status: :unprocessable_entity
      end
      format.html do
        flash.now[:alert] = message
        @user = User.new(email: email)
        render :new_session, status: :unprocessable_entity
      end
      format.json { render json: { error: message }, status: :unauthorized }
    end
  end

  def user_params
    params.expect(user: [:email, :username, :password, :password_confirmation,
                         :first_name, :last_name, :role])
  end

end
