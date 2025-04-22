# frozen_string_literal: true

module Api
  module V1
    class Users < Base
      resource :users do
        desc "Get user information"
        params do
          requires :id, type: String, desc: "Global PD User ID"
        end
        get ":id" do
          authenticate_service!

          user = User.find_by(pd_id: params[:id], active: true)

          error!("User not found", 404) unless user

          {
            pd_id: user.pd_id,
            email: user.email,
            created_at: user.created_at
            # Add other fields as needed
          }
        end

        desc "Register a new user"
        params do
          requires :first_name, type: String, desc: "User's first name"
          requires :last_name, type: String, desc: "User's last name"
          requires :email, type: String, desc: "User's email address"
          requires :password, type: String, desc: "User's password"
          requires :password_confirmation, type: String, desc: "Password confirmation"
        end
        post do
          authenticate_service!

          # Check if email already exists
          if User.exists?(email: params[:email])
            status 422
            return { error: "Email is already taken" }
          end

          # Create the user
          user = User.new(
            first_name: params[:first_name],
            last_name: params[:last_name],
            email: params[:email],
            password: params[:password],
            password_confirmation: params[:password_confirmation]
          )

          if user.save
            # Successfully created
            {
              success: true,
              pd_id: user.pd_id,
              email: user.email,
              created_at: user.created_at
            }
          else
            # Failed validation
            status 422
            {
              success: false,
              errors: user.errors.full_messages
            }
          end
        end
      end

    end
  end
end
