Rails.application.routes.draw do
  # Authentication routes
  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'
  
  get 'signup', to: 'people#new'
  post 'signup', to: 'people#create'
  
  # People management (unified user, employee, client management)
  resources :people, only: [:index, :show, :new, :create, :update, :destroy] do
    member do
      patch :update_role
    end
  end
  
  # Dashboard (protected)
  get 'dashboard', to: 'dashboard#index'
  
  # Settings (protected)
  get 'settings', to: 'settings#index'
  
  # Notes (protected)
  resources :notes, only: [:index, :show, :edit, :create, :update, :destroy]
  
  # Todos (protected)
  resources :todos, only: [:index, :show, :edit, :create, :update, :destroy] do
    member do
      patch :toggle
    end
    collection do
      delete :clear_completed
    end
  end
  
  # File Items (protected)
  resources :file_items, only: [:index, :show, :edit, :create, :update, :destroy] do
    member do
      get :download
      get :preview
    end
  end
  
  # Messages (protected)
         resources :messages, only: [:index, :show, :create]
         
         # R&D Projects (protected)
         resources :rnd_projects, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
           resources :rnd_expenditures, only: [:create, :edit, :update, :destroy]
         end
         
         # Grant Applications (protected)
         resources :grant_applications do
           member do
             patch :submit
             patch :change_status
           end
         end
         
         # Admin Feature Flags
         namespace :admin do
           resources :feature_flags do
             member do
               patch :update_user_access
             end
           end
         end
  
  # Pages
  get 'home', to: 'pages#home'
  
  # Existing routes
  get 'inertia-example', to: 'inertia_example#index'
  get 'hello', to: 'hello#index'

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "pages#home"
end
