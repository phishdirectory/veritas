# frozen_string_literal: true

# app/controllers/users_controller.rb
class UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create, :username_conflict]

  layout "sessions", only: [:new]
  def new
    redirect_to root_path if current_user
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      sign_in(user: @user)
      redirect_to root_path, notice: "Account successfully created!"
    else
      # Check if this is a username conflict error
      if @user.errors[:base]&.any? { |message| message.include?("snafu") }
        redirect_to username_conflict_path
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  def username_conflict
    render "errors/username_conflict", layout: false
  end

  def update
    @user = current_user
    if @user.update(user_params)
      redirect_to root_path, notice: "Account successfully updated!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
  end

end
