# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  describe "input sanitization" do
    describe "POST #create" do
      context "with SQL injection attempts" do
        it "rejects first_name with SELECT statement and notifies ops" do
          expect(NotifyOpsOnSecurityIncidentJob).to receive(:perform_later).with(
            email: "test@example.com",
            input_type: "first_name",
            malicious_input: "John'; DROP TABLE users; SELECT * FROM users WHERE '1'='1",
            ip_address: anything,
            user_agent: anything
          )
          
          post :create, params: { 
            user: { 
              first_name: "John'; DROP TABLE users; SELECT * FROM users WHERE '1'='1", 
              last_name: "Doe",
              email: "test@example.com", 
              password: "validpassword123",
              password_confirmation: "validpassword123"
            } 
          }
          
          expect(response).to have_http_status(:unprocessable_entity)
          expect(assigns(:user).errors[:base]).to include(match(/Invalid input/))
        end

        it "rejects email with SQL injection" do
          post :create, params: { 
            user: { 
              first_name: "John", 
              last_name: "Doe",
              email: "test@example.com' OR 1=1--", 
              password: "validpassword123",
              password_confirmation: "validpassword123"
            } 
          }
          
          expect(response).to have_http_status(:unprocessable_entity)
          expect(assigns(:user).errors[:base]).to include(match(/Invalid input/))
        end

        it "rejects password with SQL injection" do
          post :create, params: { 
            user: { 
              first_name: "John", 
              last_name: "Doe",
              email: "test@example.com", 
              password: "password'; DROP TABLE users; --",
              password_confirmation: "password'; DROP TABLE users; --"
            } 
          }
          
          expect(response).to have_http_status(:unprocessable_entity)
          expect(assigns(:user).errors[:base]).to include(match(/Invalid input/))
        end
      end

      context "with XSS attempts" do
        it "sanitizes first_name with script tags" do
          post :create, params: { 
            user: { 
              first_name: "<script>alert('xss')</script>John", 
              last_name: "Doe",
              email: "test@example.com", 
              password: "validpassword123",
              password_confirmation: "validpassword123"
            } 
          }
          
          # Should either sanitize or reject
          if response.status == 422
            expect(assigns(:user).errors[:base]).to include(match(/Invalid input/))
          else
            # If it sanitizes, the script tags should be escaped
            user = assigns(:user)
            expect(user.first_name).not_to include("<script>")
            expect(user.first_name).to include("&lt;script&gt;")
          end
        end
      end

      context "with buffer overflow attempts" do
        it "truncates very long input" do
          long_string = "a" * 1000
          post :create, params: { 
            user: { 
              first_name: long_string, 
              last_name: "Doe",
              email: "test@example.com", 
              password: "validpassword123",
              password_confirmation: "validpassword123"
            } 
          }
          
          # Should either truncate or reject based on implementation
          if response.status == 422
            expect(assigns(:user).errors[:base]).to include(match(/Invalid input/))
          else
            user = assigns(:user)
            expect(user.first_name.length).to be <= 255
          end
        end

        it "rejects very long password" do
          long_password = "a" * 1000
          post :create, params: { 
            user: { 
              first_name: "John", 
              last_name: "Doe",
              email: "test@example.com", 
              password: long_password,
              password_confirmation: long_password
            } 
          }
          
          expect(response).to have_http_status(:unprocessable_entity)
          expect(assigns(:user).errors[:base]).to include(match(/Invalid input/))
        end
      end

      context "with valid input" do
        it "allows normal signup" do
          post :create, params: { 
            user: { 
              first_name: "John", 
              last_name: "Doe",
              email: "test@example.com", 
              password: "validpassword123",
              password_confirmation: "validpassword123"
            } 
          }
          
          expect(response).to have_http_status(:found)  # redirect on success
        end
      end
    end
  end
end