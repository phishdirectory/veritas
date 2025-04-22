# app/controllers/api/v1/auth_controller.rb
module Api
  module V1
    class AuthController < BaseController
      def authenticate
        credentials = dehash_credentials(params[:credentials])

        unless credentials && credentials[:email] && credentials[:password]
          render json: { error: "Invalid credentials format" }, status: :bad_request
          return
        end

        user = User.find_by(email: credentials[:email])

        if user&.can_authenticate? && user.authenticate(credentials[:password])
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
