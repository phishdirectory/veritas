# frozen_string_literal: true

# app/controllers/api/v1/health_controller.rb
module Api
  module V1
    class HealthController < ApplicationController
      skip_before_action :verify_authenticity_token

      def index
        render json: { status: "ok" }
      end

    end
  end
end
