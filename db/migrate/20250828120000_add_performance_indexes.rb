class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Users table indexes
    add_index :users, :email, unique: true unless index_exists?(:users, :email)
    add_index :users, :role unless index_exists?(:users, :role)
    add_index :users, :created_at unless index_exists?(:users, :created_at)
    
    # Notes table indexes
    add_index :notes, :user_id unless index_exists?(:notes, :user_id)
    add_index :notes, :title unless index_exists?(:notes, :title)
    add_index :notes, :created_at unless index_exists?(:notes, :created_at)
    add_index :notes, :updated_at unless index_exists?(:notes, :updated_at)
    
    # Todos table indexes
    add_index :todos, :user_id unless index_exists?(:todos, :user_id)
    add_index :todos, :title unless index_exists?(:todos, :title)
    add_index :todos, :completed unless index_exists?(:todos, :completed)
    add_index :todos, :due_date unless index_exists?(:todos, :due_date)
    add_index :todos, :priority unless index_exists?(:todos, :priority)
    add_index :todos, :created_at unless index_exists?(:todos, :created_at)
    
    # Messages table indexes
    add_index :messages, :sender_id unless index_exists?(:messages, :sender_id)
    add_index :messages, :recipient_id unless index_exists?(:messages, :recipient_id)
    add_index :messages, :client_id unless index_exists?(:messages, :client_id)
    add_index :messages, :subject unless index_exists?(:messages, :subject)
    add_index :messages, :created_at unless index_exists?(:messages, :created_at)
    add_index :messages, :message_type unless index_exists?(:messages, :message_type)
    
    # R&D Projects table indexes
    add_index :rnd_projects, :client_id unless index_exists?(:rnd_projects, :client_id)
    add_index :rnd_projects, :title unless index_exists?(:rnd_projects, :title)
    add_index :rnd_projects, :status unless index_exists?(:rnd_projects, :status)
    add_index :rnd_projects, :start_date unless index_exists?(:rnd_projects, :start_date)
    add_index :rnd_projects, :end_date unless index_exists?(:rnd_projects, :end_date)
    add_index :rnd_projects, :created_at unless index_exists?(:rnd_projects, :created_at)
    
    # R&D Expenditures table indexes
    add_index :rnd_expenditures, :rnd_project_id unless index_exists?(:rnd_expenditures, :rnd_project_id)
    add_index :rnd_expenditures, :expenditure_type unless index_exists?(:rnd_expenditures, :expenditure_type)
    add_index :rnd_expenditures, :date unless index_exists?(:rnd_expenditures, :date)
    add_index :rnd_expenditures, :amount unless index_exists?(:rnd_expenditures, :amount)
    
    # Grant Applications table indexes
    add_index :grant_applications, :user_id unless index_exists?(:grant_applications, :user_id)
    add_index :grant_applications, :title unless index_exists?(:grant_applications, :title)
    add_index :grant_applications, :status unless index_exists?(:grant_applications, :status)
    add_index :grant_applications, :deadline unless index_exists?(:grant_applications, :deadline)
    add_index :grant_applications, :created_at unless index_exists?(:grant_applications, :created_at)
    
    # File Items table indexes
    add_index :file_items, :user_id unless index_exists?(:file_items, :user_id)
    add_index :file_items, :name unless index_exists?(:file_items, :name)
    add_index :file_items, :category unless index_exists?(:file_items, :category)
    add_index :file_items, :file_type unless index_exists?(:file_items, :file_type)
    add_index :file_items, :created_at unless index_exists?(:file_items, :created_at)
    
    # Notifications table indexes
    add_index :notifications, :user_id unless index_exists?(:notifications, :user_id)
    add_index :notifications, :read unless index_exists?(:notifications, :read)
    add_index :notifications, :notification_type unless index_exists?(:notifications, :notification_type)
    add_index :notifications, :created_at unless index_exists?(:notifications, :created_at)
    
    # Feature flags and access indexes
    add_index :feature_flags, :name, unique: true unless index_exists?(:feature_flags, :name)
    add_index :feature_flags, :enabled unless index_exists?(:feature_flags, :enabled)
    add_index :user_feature_accesses, [:user_id, :feature_flag_id], unique: true unless index_exists?(:user_feature_accesses, [:user_id, :feature_flag_id])
    
    # Clients table indexes
    add_index :clients, :user_id unless index_exists?(:clients, :user_id)
    add_index :clients, :employee_id unless index_exists?(:clients, :employee_id)
    add_index :clients, :created_at unless index_exists?(:clients, :created_at)
  end
end
