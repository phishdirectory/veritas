# frozen_string_literal: true

# app/controllers/api/v1/base_controller.rb
module Api
  module V1
    class BaseController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_service

      private

      def authenticate_service
        api_key = request.headers["X-Api-Key"]

        if api_key.blank?
          render json: { error: "API key missing" }, status: :unauthorized
          return
        end

        key = ApiService::Key.find_by(api_key: api_key)

        # Record the usage attempt
        if key
          key.usages.create(
            request_path: request.path,
            request_method: request.method,
            ip_address: request.remote_ip,
            response_code: key.may_use? && key.service.active? ? 200 : 401
          )

          # Log deprecated keys
          Rails.logger.warn("Deprecated key used: Service #{key.service.name}, Key ID #{key.id}") if key.deprecated?

          # Log revoked keys
          Rails.logger.warn("Revoked key attempted: Service #{key.service.name}, Key ID #{key.id}") if key.revoked?
        end

        @current_service = key&.may_use? ? key.service : nil
        @current_service = nil unless @current_service&.active?

        return if @current_service

        render json: { error: "Invalid API key" }, status: :unauthorized

      end

      def current_service
        @current_service
      end

      def current_key
        api_key = request.headers["X-Api-Key"]
        ApiService::Key.find_by(api_key: api_key)
      end

      def dehash_credentials(hashed_credentials)
        # Simple implementation for demonstration purposes
        begin
          data = Base64.decode64(hashed_credentials)
          JSON.parse(data).symbolize_keys
        rescue => e
          Rails.logger.error("Failed to dehash credentials: #{e.message}")
          nil
        end
      end

    end
  end
end
