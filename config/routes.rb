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

         # Companies directory
         resources :companies, only: [:index, :show, :new, :create]
         
         # R&D Projects (protected)
         resources :rnd_projects, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
           resources :rnd_expenditures, only: [:create, :edit, :update, :destroy]
         end
         
         # Grant Applications (protected)
        resources :grant_applications do
          member do
            patch :change_stage
          end
          collection do
            post :link_companies
            post :add_demo_data
            get :debug_data
            post :fix_company_links
          end
          resources :grant_checklist_items, only: [:create, :update]
        end
         
         # Admin Feature Flags
         namespace :admin do
           resources :feature_flags, only: [:index, :new, :create, :edit, :update, :destroy] do
             member do
               patch :update_user_access
             end
           end
         end
         
         # App Inspector (Admin only)
         get 'inspector', to: 'inspector#index'
         
         # Search
         get 'search', to: 'search#index'
         
         # Notifications
         resources :notifications, only: [:index] do
           member do
             patch :mark_as_read
           end
           collection do
             patch :mark_all_as_read
           end
         end
         
         # Health check endpoints
         get 'health', to: 'health#index'
         get 'health/database', to: 'health#database'
         get 'health/cache', to: 'health#cache'
         

  
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
