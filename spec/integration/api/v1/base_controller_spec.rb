# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::UsersController, type: :request do
  let(:service) { create(:service, :active) }
  let(:api_key) { "test-api-key" }
  let(:service_key) { create(:service_key, api_key: api_key, service: service) }
  let(:user) { create(:user) }

  before do
    # Ensure the key is created before each test
    service_key
  end

  describe "API key authentication" do
    context "with a valid API key" do
      it "allows access to a protected endpoint" do
        get api_v1_user_path(user.pd_id), headers: { "X-Api-Key" => api_key }
        expect(response).not_to have_http_status(:unauthorized)
      end
    end

    context "with a missing API key" do
      it "returns unauthorized" do
        get api_v1_user_path(user.pd_id)
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("API key missing")
      end
    end

    context "with an invalid API key" do
      it "returns unauthorized" do
        get api_v1_user_path(user.pd_id), headers: { "X-Api-Key" => "invalid-key" }
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("Invalid API key")
      end
    end

    context "with a revoked key" do
      before { service_key.update(revoked: true) }
      it "returns unauthorized" do
        get api_v1_user_path(user.pd_id), headers: { "X-Api-Key" => api_key }
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("Invalid API key")
      end
    end

    context "with a deprecated key" do
      before { service_key.update(deprecated: true) }
      it "still allows access if key is otherwise valid" do
        get api_v1_user_path(user.pd_id), headers: { "X-Api-Key" => api_key }
        expect(response).not_to have_http_status(:unauthorized)
      end
    end
  end
end
