Rails.application.routes.draw do
  devise_for :parents

  resources :game_sessions
  resources :games
  resources :token_transactions
  resources :chore_assignments
  resources :chores
  resources :children
  resources :parents

  # Child PIN login
  get 'child_login', to: 'child_sessions#new', as: :new_child_session
  post 'child_login', to: 'child_sessions#create', as: :child_session
  delete 'child_logout', to: 'child_sessions#destroy', as: :destroy_child_session

  namespace :admin do
    root to: 'dashboard#index'
    resources :dashboard, only: [:index]
  end
  # Root path
  root to: 'home#index'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
