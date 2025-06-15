# frozen_string_literal: true

# app/controllers/api/v1/base_controller.rb
module Api
  module V1
    class BaseController < ApplicationController
      skip_before_action :verify_authenticity_token
      skip_before_action :authenticate_user!
      before_action :authenticate_service
      around_action :log_api_request

      private

      def authenticate_service
        api_key = request.headers["X-Api-Key"]

        if api_key.blank?
          render json: { error: "API key missing" }, status: :unauthorized
          return
        end

        key = Service::Key.find_by(api_key: api_key)

        # Store the key for logging purposes
        @current_key_for_logging = key

        # Create initial usage record for detailed logging
        if key
          @usage_record = key.usages.create(
            request_path: request.path,
            request_method: request.method,
            ip_address: request.remote_ip,
            response_code: key.may_use? && key.service.active? ? 200 : 401,
            user_agent: request.user_agent,
            requested_at: Time.current
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

      def log_api_request
        start_time = Time.current

        yield

        duration_ms = ((Time.current - start_time) * 1000).round

        # Update the usage record with comprehensive logging data
        if @usage_record
          update_usage_record_with_details(duration_ms)
        end
      rescue => e
        # Log error details and ensure usage record is updated even on errors
        Rails.logger.error("API request error: #{e.message}")
        @usage_record&.update(
          response_code: 500,
          duration_ms: ((Time.current - start_time) * 1000).round,
          response_body: { error: "Internal server error", message: e.message }.to_json
        )
        raise
      end

      def update_usage_record_with_details(duration_ms)
        return unless @usage_record

        # Filter sensitive data from headers and params
        filtered_headers = filter_sensitive_headers(request.headers.to_h)
        filtered_params = filter_sensitive_params(request.params)
        filtered_response_headers = filter_sensitive_headers(response.headers.to_h) if response

        # Extract user information if available
        user_id = nil
        if respond_to?(:current_user) && current_user
          user_id = current_user.id
        elsif filtered_params["user_id"]
          user_id = filtered_params["user_id"]
        end

        # Get request body (for POST/PUT/PATCH requests)
        request_body = nil
        if %w[POST PUT PATCH].include?(request.method) && request.raw_post.present?
          begin
            request_body = filter_sensitive_params(JSON.parse(request.raw_post)).to_json
          rescue JSON::ParserError
            request_body = "[Non-JSON request body]"
          end
        end

        # Get response body if it's JSON
        response_body = nil
        if response && response.body.present?
          begin
            parsed_response = JSON.parse(response.body)
            response_body = filter_sensitive_params(parsed_response).to_json
          rescue JSON::ParserError
            response_body = "[Non-JSON response body]"
          end
        end

        # Update the usage record
        @usage_record.update(
          response_code: response&.status || 500,
          duration_ms: duration_ms,
          request_headers: filtered_headers.to_json,
          request_body: request_body,
          response_headers: filtered_response_headers&.to_json,
          response_body: response_body,
          user_id: user_id
        )

        # Send metrics to StatsD/Grafana
        send_metrics_to_statsd
      rescue => e
        Rails.logger.error("Failed to update usage record: #{e.message}")
      end

      def send_metrics_to_statsd
        return unless @usage_record

        # Record metrics using the ApiMetricsService
        ApiMetricsService.record_request(@usage_record)

        # Also record real-time metrics for immediate Grafana visibility
        ApiMetricsService.record_endpoint_metrics(
          @usage_record.request_path,
          @usage_record.request_method,
          @usage_record.duration_ms,
          @usage_record.response_code,
          @current_service&.name
        )
      rescue => e
        Rails.logger.error("Failed to send metrics to StatsD: #{e.message}")
      end

      def filter_sensitive_headers(headers)
        # Remove sensitive headers
        sensitive_headers = %w[
          authorization x-api-key cookie set-cookie
          x-csrf-token x-forwarded-for x-real-ip
        ]

        headers.reject { |key, _| sensitive_headers.include?(key.downcase) }
      end

      def filter_sensitive_params(params)
        # Use Rails' built-in parameter filtering
        filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
        filter.filter(params)
      end

    end
  end
end
