# frozen_string_literal: true

# app/controllers/admin/keys_controller.rb
module Admin
  class KeysController < ApplicationController
    before_action :require_admin
    before_action :set_service
    before_action :set_key, only: %i[show deprecate revoke]

    def show; end

    def create
      @key = @service.generate_key(params[:notes])

      if @key.persisted?
        redirect_to admin_service_path(@service), notice: "New key was generated."
      else
        redirect_to admin_service_path(@service), alert: "Failed to generate key."
      end
    end

    def rotate
      current_key = @service.current_key

      if current_key
        current_key.rotate!(params[:notes])
        redirect_to admin_service_path(@service), notice: "Key was rotated."
      else
        @key = @service.generate_key(params[:notes])
        redirect_to admin_service_path(@service), notice: "New key was generated."
      end
    end

    def deprecate
      @key.deprecate!
      redirect_to admin_service_key_path(@service, @key), notice: "Key was deprecated."
    end

    def revoke
      @key.revoke!
      redirect_to admin_service_key_path(@service, @key), notice: "Key was revoked."
    end

    private

    def set_service
      @service = Service.find(params[:service_id])
    end

    def set_key
      @key = @service.keys.find(params[:id])
    end

    def require_admin
      # TODO: Implement your admin authentication logic here
      redirect_to login_path unless current_user
    end

  end
end
