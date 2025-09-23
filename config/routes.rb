# Routes Configuration
# 
# This file defines all the routes for the RSID application.
# Routes are organized following RESTful conventions and grouped by concern.
#
# Organization:
# 1. Public routes (no authentication required)
# 2. Authentication routes (RESTful sessions)
# 3. Protected routes (require authentication)
# 4. Admin routes (require admin privileges)
# 5. Development routes (development only)
Rails.application.routes.draw do
  # ========================================
  # PUBLIC ROUTES (No authentication required)
  # ========================================
  
  # Root and landing pages
  root "pages#home"
  get 'home', to: 'pages#home'
  
  # Health check endpoints
  get "up" => "rails/health#show", as: :rails_health_check
  get 'health', to: 'health#index'
  get 'health/database', to: 'health#database'
  get 'health/cache', to: 'health#cache'
  
  # Development/example routes
  get 'inertia-example', to: 'inertia_example#index'
  get 'hello', to: 'hello#index'

  # ========================================
  # AUTHENTICATION ROUTES (RESTful)
  # ========================================
  
  # RESTful session management
  resources :sessions, only: [:new, :create, :destroy] do
    collection do
      get :new, as: :login
      delete :destroy, as: :logout
    end
  end
  
  # Friendly auth aliases used by the frontend
  get   'login',  to: 'sessions#new'
  post  'login',  to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'
  
  # User registration
  resources :registrations, only: [:new, :create] do
    collection do
      get :new, as: :signup
    end
  end

  # ========================================
  # PROTECTED ROUTES (Require authentication)
  # ========================================
  
  # Dashboard and settings
  get 'dashboard', to: 'dashboard#index'
  get 'settings', to: 'settings#index'
  
  # Search
  get 'search', to: 'search#index'
  
  # User management
  resources :people, only: [:index, :show, :new, :create, :update, :destroy] do
    member do
      patch :update_role
    end
  end
  
  # Companies
  resources :companies, only: [:index, :show, :new, :create]
  
  # Grant competitions
  resources :grant_competitions, only: [:index, :show]
  
  # Grant applications with nested resources
  resources :grant_applications do
    member do
      patch :change_stage
    end
    
    # Nested checklist items
    resources :grant_checklist_items, only: [] do
      collection do
        post :upsert
      end
    end
    
    # Nested documents
    resources :grant_documents, only: [:index, :create, :destroy]
  end
  
  # R&D Claims with nested resources
  resources :rnd_claims, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    member do
      patch :change_stage
    end
    
    # Nested expenditures
    resources :rnd_claim_expenditures, only: [:create, :edit, :update, :destroy]
    
    # Nested projects
    resources :rnd_claim_projects, only: [:index, :show, :new, :create, :edit, :update, :destroy]
  end
  
  # Messages
  resources :messages, only: [:index, :show, :create]
  
  # CNF Communications
  resources :cnf_comms, only: [:index, :show, :new, :create, :edit, :update, :destroy]
  
  # Notifications
  resources :notifications, only: [:index] do
    member do
      patch :mark_as_read
    end
    collection do
      patch :mark_all_as_read
    end
  end

  # ========================================
  # ADMIN ROUTES (Require admin privileges)
  # ========================================
  
  namespace :admin do
    # Feature flags management
    resources :feature_flags, only: [:index, :new, :create, :edit, :update, :destroy] do
      member do
        patch :update_user_access
      end
    end
    
    # Demo data management (development only)
    resources :demo_data, only: [] do
      collection do
        post :link_companies
        post :add_demo_data
        post :add_massive_demo_data
        get :debug_data
        post :fix_company_links
      end
    end
  end
  
  # App Inspector (Admin only)
  get 'inspector', to: 'inspector#index'

  # ========================================
  # DEVELOPMENT ROUTES (Development only)
  # ========================================
  
  # Development routes moved to Admin::DemoDataController
end
