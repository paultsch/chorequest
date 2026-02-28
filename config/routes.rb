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
  post 'chore_assignments/bulk_update', to: 'chore_assignments#bulk_update', as: :bulk_update_chore_assignments
  get  'chore_attempts/new/:chore_assignment_id', to: 'chore_attempts#new', as: :new_chore_attempt
  post 'chore_attempts', to: 'chore_attempts#create', as: :chore_attempts
  post 'chore_attempts/:id/approve', to: 'chore_attempts#approve', as: :approve_chore_attempt
  post 'chore_attempts/:id/reject', to: 'chore_attempts#reject', as: :reject_chore_attempt
  resources :chores do
    collection do
      post :improve_definition
    end
  end
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
  # Super-admin namespace and Devise routes (separate from customer /admin)
  devise_for :admin_users, path: 'super_admin', class_name: 'AdminUser'

  namespace :super_admin do
    root to: 'dashboard#index'
    resources :dashboard, only: [:index]
    resources :parents, only: [:index, :show, :edit, :update] do
      member do
        post :impersonate
        post :reactivate
      end
    end
    post 'stop_impersonation', to: 'impersonations#destroy', as: :stop_impersonation
  end
  # Root path
  root to: 'home#index'

  # Public child view by token (no authentication)
  get '/public/:token', to: 'public#show', as: :public_child
  post '/public/:token/complete/:id', to: 'public#complete', as: :public_complete_assignment
  get  '/public/:token/attempt/:assignment_id', to: 'public#new_attempt', as: :public_new_attempt
  post '/public/:token/attempt', to: 'public#create_attempt', as: :public_create_attempt
  get '/public/:token/play', to: 'public#play', as: :public_play
  post '/public/:token/start_session', to: 'public#start_session', as: :public_start_session
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
