class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Users table indexes
    add_index :users, :email, unique: true
    add_index :users, :role
    add_index :users, :created_at
    
    # Notes table indexes
    add_index :notes, :user_id
    add_index :notes, :title
    add_index :notes, :created_at
    add_index :notes, :updated_at
    
    # Todos table indexes
    add_index :todos, :user_id
    add_index :todos, :title
    add_index :todos, :completed
    add_index :todos, :due_date
    add_index :todos, :priority
    add_index :todos, :created_at
    
    # Messages table indexes
    add_index :messages, :sender_id
    add_index :messages, :recipient_id
    add_index :messages, :client_id
    add_index :messages, :subject
    add_index :messages, :created_at
    add_index :messages, :message_type
    
    # R&D Projects table indexes
    add_index :rnd_projects, :client_id
    add_index :rnd_projects, :title
    add_index :rnd_projects, :status
    add_index :rnd_projects, :start_date
    add_index :rnd_projects, :end_date
    add_index :rnd_projects, :created_at
    
    # R&D Expenditures table indexes
    add_index :rnd_expenditures, :rnd_project_id
    add_index :rnd_expenditures, :expenditure_type
    add_index :rnd_expenditures, :date
    add_index :rnd_expenditures, :amount
    
    # Grant Applications table indexes
    add_index :grant_applications, :user_id
    add_index :grant_applications, :title
    add_index :grant_applications, :status
    add_index :grant_applications, :deadline
    add_index :grant_applications, :created_at
    
    # File Items table indexes
    add_index :file_items, :user_id
    add_index :file_items, :name
    add_index :file_items, :category
    add_index :file_items, :file_type
    add_index :file_items, :created_at
    
    # Notifications table indexes
    add_index :notifications, :user_id
    add_index :notifications, :read
    add_index :notifications, :notification_type
    add_index :notifications, :created_at
    
    # Feature flags and access indexes
    add_index :feature_flags, :name, unique: true
    add_index :feature_flags, :enabled
    add_index :user_feature_accesses, [:user_id, :feature_flag_id], unique: true
    
    # Clients table indexes
    add_index :clients, :user_id
    add_index :clients, :employee_id
    add_index :clients, :created_at
  end
end
