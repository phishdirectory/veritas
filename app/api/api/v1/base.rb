# frozen_string_literal: true

module Api
  module V1
    class Base < Grape::API
      version "v1", using: :path
      format :json
      prefix :api

      helpers do
        def authenticate_service!
          api_key = headers["X-Api-Key"]

          error!("API key missing", 401) if api_key.blank?

          # Find the key
          key = Service::Key.find_by(api_key: api_key)

          # Record the usage attempt, even if it fails
          if key
            key.usages.create(
              request_path: request.path,
              request_method: request.request_method,
              ip_address: request.ip,
              response_code: key.may_use? && key.service.active? ? 200 : 401
            )

            # Log usage of deprecated keys
            if key.deprecated?
              Rails.logger.warn("Deprecated key used: Service #{key.service.name}, Key ID #{key.id}")
            end

            # Log usage of revoked keys
            if key.revoked?
              Rails.logger.warn("Revoked key attempted: Service #{key.service.name}, Key ID #{key.id}")
            end
          end

          @current_service = key&.may_use? ? key.service : nil
          @current_service = nil unless @current_service&.active?

          error!("Invalid API key", 401) unless @current_service
        end

        attr_reader :current_service

        def current_key
          api_key = headers["X-Api-Key"]
          Service::Key.find_by(api_key: api_key)
        end

        def dehash_credentials(hashed_credentials)
          # Get the key that was used for authentication
          current_key

          # This is a simple implementation for demonstration purposes
          # In production, use proper encryption/decryption with the hash_key
          begin
            data = Base64.decode64(hashed_credentials)
            JSON.parse(data).symbolize_keys
          rescue => e
            Rails.logger.error("Failed to dehash credentials: #{e.message}")
            nil
          end
        end
      end

      # Add after filter to update response code in usage log
      after do
        if current_key
          usage = current_key.usages.where(
            request_path: request.path,
            request_method: request.request_method
          ).order(created_at: :desc).first

          usage&.update(response_code: status)
        end
      end

    end
  end
end
