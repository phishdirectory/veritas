# frozen_string_literal: true

# spec/integration/api/v1/users_spec.rb
require "swagger_helper"

RSpec.describe "API V1 Users", type: :request do
  path "/api/v1/users" do
    post "Creates a user" do
      tags "Users"
      consumes "application/json"
      produces "application/json"
      parameter name: :'X-Api-Key', in: :header, type: :string, required: true, description: "API key"
      parameter name: :hashed_data, in: :body, schema: {
        type: :object,
        properties: {
          hashed_data: { type: :string }
        },
        required: ["hashed_data"]
      }

      response "200", "user created" do
        let(:service) { create(:service, :active) }
        let(:api_key) { "test-api-key" }
        let(:service_key) { create(:service_key, api_key: api_key, service: service) }
        let(:'X-Api-Key') { api_key }
        let(:hashed_data) { { hashed_data: "valid-hash" } }

        before do
          allow_any_instance_of(Api::V1::UsersController).to receive(:dehash_credentials).and_return(
            {
              first_name: "Jane",
              last_name: "Doe",
              email: "jane@example.com",
              password: "password",
              password_confirmation: "password"
            }
          )
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["success"]).to eq(true)
          expect(data["email"]).to eq("jane@example.com")
        end
      end

      response "400", "invalid or missing hashed data" do
        let(:'X-Api-Key') { "test-api-key" }
        let(:hashed_data) { { hashed_data: nil } }

        before do
          allow_any_instance_of(Api::V1::UsersController).to receive(:dehash_credentials).and_return(nil)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Invalid or missing hashed data")
        end
      end

      response "422", "email already taken" do
        let(:service) { create(:service, :active) }
        let(:api_key) { "test-api-key" }
        let(:service_key) { create(:service_key, api_key: api_key, service: service) }
        let(:'X-Api-Key') { api_key }
        let(:hashed_data) { { hashed_data: "valid-hash" } }

        before do
          create(:user, email: "jane@example.com")
          allow_any_instance_of(Api::V1::UsersController).to receive(:dehash_credentials).and_return(
            {
              first_name: "Jane",
              last_name: "Doe",
              email: "jane@example.com",
              password: "password",
              password_confirmation: "password"
            }
          )
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Email is already taken")
        end
      end
    end
  end
end
