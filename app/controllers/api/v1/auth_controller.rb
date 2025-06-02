# frozen_string_literal: true

# app/controllers/api/v1/auth_controller.rb
module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_user!

      def authenticate
        # Dehash the credentials from the request
        credentials = dehash_credentials(params[:credentials])

        unless credentials && credentials[:email] && credentials[:password]
          render json: { error: "Invalid credentials format" }, status: :bad_request
          return
        end

        user = User.find_by(email: credentials[:email])

        if user&.can_authenticate? && user.authenticate(credentials[:password])
          # Log the successful authentication
          Rails.logger.info("User authenticated by service #{current_service.name}: #{user.pd_id}")

          render json: {
            authenticated: true,
            pd_id: user.pd_id
          }
        else
          render json: { authenticated: false }, status: :unauthorized
        end
      end

    end
  end
end
