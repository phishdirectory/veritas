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

        key = Service::Key.find_by(api_key: api_key)

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
        @current_key = key if @current_service

        return if @current_service

        render json: { error: "Invalid API key" }, status: :unauthorized
      end

      def current_service
        @current_service
      end

      def current_key
        @current_key
      end

      def dehash_credentials(hashed_data)
        return nil if hashed_data.blank? || current_key.nil?

        begin
          # Get the hash key from the current key
          hash_key = current_key.hash_key

          # First decode the base64
          decoded = Base64.strict_decode64(hashed_data)

          # Use OpenSSL to decrypt the data with the hash_key
          cipher = OpenSSL::Cipher.new("aes-256-cbc")
          cipher.decrypt

          # Create key and iv from the hash_key
          key = Digest::SHA256.digest(hash_key)[0...32]
          iv = hash_key[0...16].ljust(16, "0")

          cipher.key = key
          cipher.iv = iv

          # Decrypt the data
          decrypted = cipher.update(decoded) + cipher.final

          # Parse the JSON
          JSON.parse(decrypted).symbolize_keys
        rescue => e
          Rails.logger.error("Failed to dehash data: #{e.message}")
          nil
        end
      end

    end
  end
end
