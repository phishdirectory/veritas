# frozen_string_literal: true

# app/controllers/admin/services_controller.rb
module Admin
  class ServicesController < ApplicationController
    before_action :require_admin
    before_action :set_service, only: %i[show edit update suspend reactivate decommission]

    def index
      @services = Service.order(:name)
    end

    def show
      @keys = @service.keys.order(created_at: :desc)
    end

    def new
      @service = Service.new
    end

    def edit; end

    def create
      @service = Service.new(service_params)

      if @service.save
        # Generate initial key
        @service.generate_key("Initial key")
        redirect_to admin_service_path(@service),
                    notice: "Service was successfully created."
      else
        render :new
      end
    end

    def update
      if @service.update(service_params)
        redirect_to admin_service_path(@service),
                    notice: "Service was successfully updated."
      else
        render :edit
      end
    end

    def suspend
      @service.suspend!
      redirect_to admin_service_path(@service), notice: "Service was suspended."
    end

    def reactivate
      @service.reactivate!
      redirect_to admin_service_path(@service), notice: "Service was reactivated."
    end

    def decommission
      @service.decommission!
      redirect_to admin_service_path(@service), notice: "Service was decommissioned."
    end

    private

    def set_service
      @service = Service.find(params[:id])
    end

    def service_params
      params.expect(service: [:name])
    end

    def require_admin
      # TODO: Implement your admin authentication logic here
      redirect_to login_path unless current_user
    end

  end
end
