# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuthController, type: :controller do
  describe "POST #login" do
    let(:user) { create(:user, email: "test@example.com", password: "validpassword") }

    context "when email contains SQL injection" do
      before do
        allow(NotifyOpsOnSecurityIncidentJob).to receive(:perform_later)
      end

      it "rejects email with SELECT statement" do
        post :login, params: { user: { email: "test@example.com' OR 1=1; SELECT * FROM users--", password: "validpassword" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "notifies ops of SQL injection attempt" do
        post :login, params: { user: { email: "test@example.com' OR 1=1; SELECT * FROM users--", password: "validpassword" } }
        expect(NotifyOpsOnSecurityIncidentJob).to have_received(:perform_later)
      end

      it "shows invalid input error message" do
        post :login, params: { user: { email: "test@example.com' OR 1=1; SELECT * FROM users--", password: "validpassword" } }
        expect(flash[:alert]).to include("Invalid input")
      end

      it "rejects email with malicious SQL comments" do
        post :login, params: { user: { email: "test@example.com'--", password: "validpassword" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "shows error for SQL comments" do
        post :login, params: { user: { email: "test@example.com'--", password: "validpassword" } }
        expect(flash[:alert]).to include("Invalid input")
      end
    end

    context "when password contains SQL injection" do
      before do
        allow(NotifyOpsOnSecurityIncidentJob).to receive(:perform_later)
      end

      it "rejects password with SELECT statement" do
        post :login, params: { user: { email: "test@example.com", password: "password' OR 1=1; SELECT * FROM users--" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "notifies ops of password injection attempt" do
        post :login, params: { user: { email: "test@example.com", password: "password' OR 1=1; SELECT * FROM users--" } }
        expect(NotifyOpsOnSecurityIncidentJob).to have_received(:perform_later)
      end

      it "shows invalid input error for password injection" do
        post :login, params: { user: { email: "test@example.com", password: "password' OR 1=1; SELECT * FROM users--" } }
        expect(flash[:alert]).to include("Invalid input")
      end

      it "rejects password with SQL comments" do
        post :login, params: { user: { email: "test@example.com", password: "password'--" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "shows error for password SQL comments" do
        post :login, params: { user: { email: "test@example.com", password: "password'--" } }
        expect(flash[:alert]).to include("Invalid input")
      end

      it "rejects password with UNION attack" do
        post :login, params: { user: { email: "test@example.com", password: "password' UNION SELECT username,password FROM users WHERE '1'='1" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "shows error for UNION attack" do
        post :login, params: { user: { email: "test@example.com", password: "password' UNION SELECT username,password FROM users WHERE '1'='1" } }
        expect(flash[:alert]).to include("Invalid input")
      end
    end

    context "when input contains XSS attempts" do
      it "sanitizes email with script tags" do
        post :login, params: { user: { email: "<script>alert('xss')</script>test@example.com", password: "validpassword" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with valid input" do
      it "allows normal login" do
        post :login, params: { user: { email: user.email, password: "validpassword" } }
        expect(response).to have_http_status(:found)
      end
    end
  end
end
