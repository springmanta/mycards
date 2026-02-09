Rails.application.routes.draw do
  get "sets/index"
  get "sets/show"
  resource :session, only: [:new, :create, :destroy]
  resources :passwords, param: :token, only: [:new, :create, :edit, :update]
  resource :registration, only: [:new, :create]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root to: "home#index"
  resources :collections, only: [ :index, :show, :new, :create, :edit, :update, :destroy ]
  resources :collection_cards, only: [ :index, :show, :new, :create, :edit, :update, :destroy ]
  resources :sets, param: :code, only: [ :index, :show ] do
    collection do
      get :autocomplete
    end
  end
  resources :scans, only: [ :new, :create ]

  get "cards/autocomplete", to: "cards#autocomplete"

  resources :cards do
    collection do
      get :search
    end
  end
end
