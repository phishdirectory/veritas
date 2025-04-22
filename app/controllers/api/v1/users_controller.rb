# frozen_string_literal: true

# app/controllers/api/v1/users_controller.rb
module Api
  module V1
    class UsersController < BaseController
      def show
        user = User.find_by(pd_id: params[:id])

        unless user
          render json: { error: "User not found" }, status: :not_found
          return
        end

        render json: {
          pd_id: user.pd_id,
          email: user.email,
          created_at: user.created_at
        }
      end

      def create
        # Dehash the user data using the service's hash key
        user_data = dehash_credentials(params[:hashed_data])

        unless user_data
          render json: { error: "Invalid or missing hashed data" }, status: :bad_request
          return
        end

        # Check if email already exists
        if User.exists?(email: user_data[:email])
          render json: { error: "Email is already taken" }, status: :unprocessable_entity
          return
        end

        # Create the user with the dehashed data
        user = User.new(
          first_name: user_data[:first_name],
          last_name: user_data[:last_name],
          email: user_data[:email],
          password: user_data[:password],
          password_confirmation: user_data[:password_confirmation]
        )

        # Record which service created this user
        # user.created_by_service = current_service.name if current_service

        if user.save
          # Log the successful creation
          Rails.logger.info("User created by service #{current_service.name}: #{user.pd_id}")

          render json: {
            success: true,
            pd_id: user.pd_id,
            email: user.email,
            created_at: user.created_at
          }
        else
          render json: {
            success: false,
            errors: user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

    end
  end
end
