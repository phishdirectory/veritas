# spec/integration/api/v1/auth_spec.rb
require "swagger_helper"

RSpec.describe "API V1 Auth", type: :request do
  path "/api/v1/authenticate" do
    post "Authenticate a user" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"
      parameter name: :'X-Api-Key', in: :header, type: :string, required: true, description: "API key"
      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          credentials: { type: :string }
        },
        required: ["credentials"]
      }

      response "200", "authenticated" do
        let(:service) { create(:service, :active) }
        let(:api_key) { "test-api-key" }
        let(:service_key) { create(:service_key, api_key: api_key, service: service) }
        let(:user) { create(:user, password: "password") }
        let(:'X-Api-Key') { api_key }
        let(:credentials) { { credentials: "valid-credentials" } }

        before do
          allow_any_instance_of(Api::V1::AuthController).to receive(:dehash_credentials).and_return(
            { email: user.email, password: "password" }
          )
          allow_any_instance_of(User).to receive(:can_authenticate?).and_return(true)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["authenticated"]).to eq(true)
          expect(data["pd_id"]).to eq(user.pd_id)
        end
      end

      response "400", "invalid credentials format" do
        let(:'X-Api-Key') { "test-api-key" }
        let(:credentials) { { credentials: nil } }

        before do
          allow_any_instance_of(Api::V1::AuthController).to receive(:dehash_credentials).and_return(nil)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Invalid credentials format")
        end
      end

      response "401", "unauthorized" do
        let(:service) { create(:service, :active) }
        let(:api_key) { "test-api-key" }
        let(:service_key) { create(:service_key, api_key: api_key, service: service) }
        let(:user) { create(:user, password: "password") }
        let(:'X-Api-Key') { api_key }
        let(:credentials) { { credentials: "valid-credentials" } }

        before do
          allow_any_instance_of(Api::V1::AuthController).to receive(:dehash_credentials).and_return(
            { email: user.email, password: "wrongpassword" }
          )
          allow_any_instance_of(User).to receive(:can_authenticate?).and_return(true)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["authenticated"]).to eq(false)
        end
      end
    end
  end
end
