require "sidekiq/web"
require "sidekiq/cron/web"
require_relative '../app/api/auth_pd/api.rb'

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'home#index'

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # TODO: add admin constraint
  # constraints AdminConstraint do
  #   mount Audits1984::Engine => "/console"
  #   mount Sidekiq::Web => "/sidekiq"
  #   mount Flipper::UI.app(Flipper), at: "flipper", as: "flipper"
  #   mount Blazer::Engine, at: "blazer"
  # end
  # get "/sidekiq", to: redirect("users/auth") # fallback if adminconstraint fails, meaning user is not signed in

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # Admin routes
  namespace :admin do
    resources :services do
      member do
        post "suspend"
        post "reactivate"
        post "decommission"
      end

      resources :keys, only: [ :show, :create ] do
        member do
          post "deprecate"
          post "revoke"
        end

        collection do
          post "rotate"
        end
      end
    end
  end

  # Mount the Grape API
  mount AuthPd::API => "/"


  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
