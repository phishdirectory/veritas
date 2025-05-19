# frozen_string_literal: true

# spec/integration/api/v1/health_spec.rb
require "swagger_helper"

RSpec.describe "API V1 Health", type: :request do
  path "/api/v1/health" do
    get "Health check" do
      tags "Health"
      produces "application/json"

      response "200", "ok" do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
        end
      end
    end
  end
end
