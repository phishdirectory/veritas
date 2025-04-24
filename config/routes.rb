# frozen_string_literal: true

require "sidekiq/web"
require "sidekiq/cron/web"

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root "home#index"

  # get "login", to: "sessions#new"
  # post "login", to: "sessions#create"
  # delete "logout", to: "sessions#destroy"

  # TODO: add admin constraint
  # constraints AdminConstraint do
  #   mount Audits1984::Engine => "/console"
  #   mount Sidekiq::Web => "/sidekiq"
  #   mount Flipper::UI.app(Flipper), at: "flipper", as: "flipper"
  #   mount Blazer::Engine, at: "blazer"
  # end
  # get "/sidekiq", to: redirect("users/auth") # fallback if adminconstraint fails, meaning user is not signed in

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  # API routes
  namespace :api do
    namespace :v1 do
      get "health", to: "health#index"

      post "auth/authenticate", to: "auth#authenticate"

      # Remove the namespace prefix since we're already in the namespace
      resources :users, only: [:show, :create]
      get "users/by_email", to: "users#show"
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
