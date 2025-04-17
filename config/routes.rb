# Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
require_relative '../app/api/auth_pd/api.rb'

Rails.application.routes.draw do
  root 'home#index'

  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'

  # Admin routes
  namespace :admin do
    resources :services do
      member do
        post 'suspend'
        post 'reactivate'
        post 'decommission'
      end

      resources :keys, only: [:show, :create] do
        member do
          post 'deprecate'
          post 'revoke'
        end

        collection do
          post 'rotate'
        end
      end
    end
  end

  # Mount the Grape API
  mount AuthPd::API => '/'


  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

end
