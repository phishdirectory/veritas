class HomeController < ApplicationController
  before_action :authenticate_user

  def index
  end

  private

  def authenticate_user
    redirect_to login_path unless current_user
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  helper_method :current_user
end
