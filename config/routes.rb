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
  
  
  # Messages (protected)
         resources :messages, only: [:index, :show, :create]

         # Companies directory
         resources :companies, only: [:index, :show, :new, :create]
         
         # Grant Competitions directory
         resources :grant_competitions, only: [:index, :show]
         
        # R&D Claims (protected)
        resources :rnd_claims, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
          member do
            patch :change_stage
          end
          resources :rnd_claim_expenditures, only: [:create, :edit, :update, :destroy]
          resources :rnd_claim_projects, only: [:index, :show, :new, :create, :edit, :update, :destroy]
        end
         
  # Grant Applications (protected)
 resources :grant_applications do
   member do
     patch :change_stage
   end
  resources :grant_checklist_items, only: [] do
    collection do
      post :upsert
    end
  end
  resources :grant_documents, only: [:index, :create, :destroy]
 end
         
         # CNF Communications (protected)
         resources :cnf_comms, only: [:index, :show, :new, :create, :edit, :update, :destroy]
         
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
  
  # Development-only debug routes
  if Rails.env.development?
    resources :grant_applications, only: [] do
      collection do
        post :link_companies
        post :add_demo_data
        post :add_massive_demo_data
        get :debug_data
        post :fix_company_links
      end
    end
  end
end
