# frozen_string_literal: true

# app/api/auth_pd/api.rb
require "grape"
require_relative "base"
require_relative "auth"
require_relative "users"

module Api
  class V1 < Grape::API
    mount Api::Auth
    mount Api::Users

    # Add a simple health check endpoint
    get :health do
      { status: "ok" }
    end

    # Handle 404s
    route :any, "*path" do
      error!("Not Found", 404)
    end

  end
end
