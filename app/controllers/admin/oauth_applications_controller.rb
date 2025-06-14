# frozen_string_literal: true

class Admin::OauthApplicationsController < Admin::BaseController
  before_action :set_application, only: [:show, :edit, :update, :destroy, :regenerate_secret]

  def index
    @applications = Doorkeeper::Application.order(created_at: :desc)
  end

  def show
  end

  def new
    @application = Doorkeeper::Application.new
  end

  def create
    @application = Doorkeeper::Application.new(application_params)

    if @application.save
      flash[:notice] = "OAuth application was successfully created."
      redirect_to admin_oauth_application_path(@application)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @application.update(application_params)
      redirect_to admin_oauth_application_path(@application), notice: "OAuth application was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @application.destroy
    redirect_to admin_oauth_applications_path, notice: "OAuth application was successfully deleted."
  end

  def regenerate_secret
    @application.secret = Doorkeeper::OAuth::Helpers::UniqueToken.generate
    if @application.save
      flash[:notice] = "Client secret has been regenerated. Please update your application with the new secret."
    else
      flash[:alert] = "Failed to regenerate secret."
    end
    redirect_to admin_oauth_application_path(@application)
  end

  private

  def set_application
    @application = Doorkeeper::Application.find(params[:id])
  end

  def application_params
    params.require(:doorkeeper_application).permit(:name, :redirect_uri, :scopes, :confidential)
  end

end
