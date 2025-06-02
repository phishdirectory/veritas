# frozen_string_literal: true

class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :impersonate]
  before_action :ensure_can_impersonate, only: [:impersonate]
  before_action :ensure_not_already_impersonating, only: [:impersonate]

  def index
    @users = User.order(created_at: :desc)
  end

  def show
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to admin_users_path, notice: "User was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to admin_users_path, notice: "User was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to admin_users_path, alert: "You cannot delete yourself."
    else
      @user.destroy
      redirect_to admin_users_path, notice: "User was successfully deleted."
    end
  end

  def impersonate
    if @user.is_impersonatable?(current_user)
      session[:admin_id] = current_user.id
      session[:user_id] = @user.id
      redirect_to root_path, notice: "Now impersonating #{@user.full_name}"
    else
      redirect_to admin_users_path, alert: "Cannot impersonate this user"
    end
  end

  def stop_impersonating
    if session[:admin_id]
      admin_user = User.find(session[:admin_id])
      session[:user_id] = session[:admin_id]
      session.delete(:admin_id)
      redirect_to admin_root_path, notice: "Stopped impersonating. Welcome back, #{admin_user.full_name}!"
    else
      redirect_to admin_root_path, alert: "You are not currently impersonating anyone"
    end
  end

  private

  def ensure_can_impersonate
    return if current_user.can_impersonate?

    redirect_to admin_users_path, alert: "You don't have permission to impersonate users"
  end

  def ensure_not_already_impersonating
    return unless impersonating?

    redirect_to admin_users_path, alert: "You cannot impersonate while already impersonating another user. Stop impersonating first."
  end

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :access_level, :password, :password_confirmation)
  end

end
