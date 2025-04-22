# frozen_string_literal: true

module Api
  module V1
    class API < Grape::API
      mount Api::V1::Auth
      mount Api::V1::Users

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
end
