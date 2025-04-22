# app/controllers/api/v1/users_controller.rb
module Api
  module V1
    class UsersController < BaseController
      def show
        # todo: check if the user is "active"
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
        # Check if email already exists
        if User.exists?(email: user_params[:email])
          render json: { error: "Email is already taken" }, status: :unprocessable_entity
          return
        end

        # Create the user
        user = User.new(user_params)

        if user.save
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

      private

      def user_params
        params.permit(:first_name, :last_name, :email, :password, :password_confirmation)
      end

    end
  end
end
