# frozen_string_literal: true

# OAuth 2.0 UserInfo endpoint (RFC 7662)
# This is separate from the API and only provides user information for OAuth flows
module Oauth
  class UserinfoController < ActionController::API
    before_action :doorkeeper_authorize!

    def show
      user = User.find(doorkeeper_token.resource_owner_id)
      scopes = doorkeeper_token.scopes

      response = {
        sub: user.pd_id, # Standard OAuth claim for user identifier
      }

      # Add claims based on granted scopes
      if scopes.include?("profile")
        response.merge!(
          name: user.full_name,
          given_name: user.first_name,
          family_name: user.last_name,
          preferred_username: user.username
        )
      end

      if scopes.include?("email")
        response.merge!(
          email: user.email,
          email_verified: user.email_verified?
        )
      end

      if scopes.include?("admin")
        response.merge!(
          admin: user.admin?,
          staff: user.is_staff?,
          pd_dev: user.is_pd_dev?
        )
      end

      render json: response
    end

  end
end
