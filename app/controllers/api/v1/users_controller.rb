# frozen_string_literal: true

# app/controllers/api/v1/users_controller.rb
module Api
  module V1
    class UsersController < BaseController
      def show
        # Try to find user by id parameter
        user = User.find_by(pd_id: params[:id]) if params[:id].present?

        # If no user found by id or no id provided, try email
        user ||= User.find_by(email: params[:email]) if params[:email].present?

        unless user
          render json: { error: "User not found" }, status: :not_found
          return
        end

        # switch on the service name to determine which permissions to return
        case current_service.id
        when ServiceMappings.service_name_to_id("Internal")
          # web service
          permissions = {
            global_access_level: {
              name: user.access_level,
              value: User.access_levels[user.access_level] # This gets the integer value
            }
          }
        when ServiceMappings.service_name_to_id("API")
          # api service
          permissions = {
            global_access_level: {
              name: user.access_level,
              value: User.access_levels[user.access_level] # This gets the integer value
            },
            api_access_level: {
              name: user.api_access_level,
              value: User.api_access_levels[user.api_access_level] # This gets the integer value
            }
          }
        end

        # declare json variable to hold the json response (will be send later)
        json = {
          pd_id: user.pd_id,
          first_name: user.first_name,
          last_name: user.last_name,
          email: user.email,
          permissions: permissions,
          created_at: user.created_at,
          status: user.status,
          # display locked_at only if the field is not nil
          locked_at: user.locked_at.presence,
        }

        render json: json
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
