# frozen_string_literal: true

# app/api/auth_pd/users.rb
module AuthPd
  class Users < Grape::API
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
    end

  end
end
