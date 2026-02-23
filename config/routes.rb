Rails.application.routes.draw do
  devise_for :parents

  resources :game_sessions
  resources :game_sessions do
    member do
      post :heartbeat
      post :stop
    end
  end
  resources :games
  resources :game_scores, only: [:create]
  resources :token_transactions
  resources :chore_assignments
  post 'chore_assignments/:id/approve', to: 'chore_assignments#approve', as: :approve_chore_assignment
  post 'chore_assignments/:id/reject', to: 'chore_assignments#reject', as: :reject_chore_assignment
  post 'chore_assignments/bulk_update', to: 'chore_assignments#bulk_update', as: :bulk_update_chore_assignments
  post 'chore_assignments/:id/mark_complete', to: 'chore_assignments#mark_complete', as: :mark_complete_chore_assignment
  resources :chores
  resources :children do
    member do
      post :regenerate_public_link
      post :play, to: 'children#play'
      post :start_session, to: 'children#start_session'
    end
  end
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

  # Public child view by token (no authentication)
  get '/public/:token', to: 'public#show', as: :public_child
  post '/public/:token/complete/:id', to: 'public#complete', as: :public_complete_assignment
  get '/public/:token/play', to: 'public#play', as: :public_play
  post '/public/:token/start_session', to: 'public#start_session', as: :public_start_session
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
