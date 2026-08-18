Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # /v1 の外に置く。ブラウザのトップレベル遷移で叩かれる（JSON API ではない）ため
  get "auth/:provider",          to: "oauth#start",
      constraints: { provider: Regexp.union(Oauth::Providers::NAMES) }
  get "auth/:provider/callback", to: "oauth#callback",
      constraints: { provider: Regexp.union(Oauth::Providers::NAMES) }

  namespace :v1 do
    namespace :auth do
      get "signup_context", to: "signups#show"
      post "refresh", to: "sessions#refresh"
      delete "logout", to: "sessions#logout"
    end
    namespace :me do
      get   "/",      to: "profiles#show"
      patch "/",      to: "profiles#update"
      post   "books",       to: "books#create"
      put    "books/:isbn", to: "books#update"
      delete "books/:isbn", to: "books#destroy"
    end
    get "books/search", to: "books#search"
    get "books/:isbn/users", to: "books#users"
    get "books/:isbn", to: "books#show", constraints: { isbn: /\d{13}/ }
    get "users/username/check", to: "users#check_username"
    resources :users, only: [ :create, :show ], param: :username do
      resources :books, only: [ :index, :show ], controller: "user_books", param: :isbn
    end
  end
end
