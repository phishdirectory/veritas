# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuthController, type: :controller do
  describe "input sanitization" do
    describe "POST #login" do
      let(:user) { create(:user, email: "test@example.com", password: "validpassword") }

      context "with SQL injection attempts in email" do
        it "rejects email with SELECT statement and notifies ops" do
          expect(NotifyOpsOnSecurityIncidentJob).to receive(:perform_later).with(
            email: "test@example.com' OR 1=1; SELECT * FROM users--",
            input_type: "email",
            malicious_input: "test@example.com' OR 1=1; SELECT * FROM users--",
            ip_address: anything,
            user_agent: anything
          )

          post :login, params: { user: { email: "test@example.com' OR 1=1; SELECT * FROM users--", password: "validpassword" } }

          expect(response).to have_http_status(:unprocessable_entity)
          expect(flash[:alert]).to include("Invalid input")
        end

        it "rejects email with malicious SQL comments" do
          post :login, params: { user: { email: "test@example.com'--", password: "validpassword" } }

          expect(response).to have_http_status(:unprocessable_entity)
          expect(flash[:alert]).to include("Invalid input")
        end
      end

      context "with SQL injection attempts in password" do
        it "rejects password with SELECT statement and notifies ops" do
          expect(NotifyOpsOnSecurityIncidentJob).to receive(:perform_later).with(
            email: "test@example.com",
            input_type: "password",
            malicious_input: "[REDACTED - PASSWORD FIELD]",
            ip_address: anything,
            user_agent: anything
          )

          post :login, params: { user: { email: "test@example.com", password: "password' OR 1=1; SELECT * FROM users--" } }

          expect(response).to have_http_status(:unprocessable_entity)
          expect(flash[:alert]).to include("Invalid input")
        end

        it "rejects password with SQL comments" do
          post :login, params: { user: { email: "test@example.com", password: "password'--" } }

          expect(response).to have_http_status(:unprocessable_entity)
          expect(flash[:alert]).to include("Invalid input")
        end

        it "rejects password with UNION attack" do
          post :login, params: { user: { email: "test@example.com", password: "password' UNION SELECT username,password FROM users WHERE '1'='1" } }

          expect(response).to have_http_status(:unprocessable_entity)
          expect(flash[:alert]).to include("Invalid input")
        end
      end

      context "with XSS attempts" do
        it "sanitizes email with script tags" do
          post :login, params: { user: { email: "<script>alert('xss')</script>test@example.com", password: "validpassword" } }

          expect(response).to have_http_status(:unprocessable_entity)
          # Should show sanitized version in error form
        end
      end

      context "with valid input" do
        it "allows normal login" do
          post :login, params: { user: { email: user.email, password: "validpassword" } }

          expect(response).to have_http_status(:found) # redirect on success
        end
      end
    end
  end
end
