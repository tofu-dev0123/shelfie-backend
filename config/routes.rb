Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :v1 do
    namespace :auth do
      post "login", to: "sessions#login"
      post "refresh", to: "sessions#refresh"
      delete "logout", to: "sessions#logout"
    end
    namespace :me do
      get   "/", to: "profiles#show"
      patch "/", to: "profiles#update"
    end
    get "users/username/check", to: "users#check_username"
    resources :users, only: [ :create, :show ], param: :username
  end
end
