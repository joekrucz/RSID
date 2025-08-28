class AddDatabaseConstraints < ActiveRecord::Migration[8.0]
  def change
    # Add foreign key constraints (only if they don't exist)
    add_foreign_key :notes, :users, on_delete: :cascade unless foreign_key_exists?(:notes, :users)
    add_foreign_key :todos, :users, on_delete: :cascade unless foreign_key_exists?(:todos, :users)
    add_foreign_key :messages, :users, column: :sender_id, on_delete: :cascade unless foreign_key_exists?(:messages, column: :sender_id)
    add_foreign_key :messages, :users, column: :recipient_id, on_delete: :cascade unless foreign_key_exists?(:messages, column: :recipient_id)
    add_foreign_key :messages, :clients, on_delete: :cascade unless foreign_key_exists?(:messages, :clients)
    add_foreign_key :rnd_projects, :clients, on_delete: :cascade unless foreign_key_exists?(:rnd_projects, :clients)
    add_foreign_key :rnd_expenditures, :rnd_projects, on_delete: :cascade unless foreign_key_exists?(:rnd_expenditures, :rnd_projects)
    add_foreign_key :grant_applications, :users, on_delete: :cascade unless foreign_key_exists?(:grant_applications, :users)
    add_foreign_key :grant_documents, :grant_applications, on_delete: :cascade unless foreign_key_exists?(:grant_documents, :grant_applications)
    add_foreign_key :file_items, :users, on_delete: :cascade unless foreign_key_exists?(:file_items, :users)
    add_foreign_key :notifications, :users, on_delete: :cascade unless foreign_key_exists?(:notifications, :users)
    add_foreign_key :clients, :users, on_delete: :cascade unless foreign_key_exists?(:clients, :users)
    add_foreign_key :clients, :users, column: :employee_id, on_delete: :nullify unless foreign_key_exists?(:clients, column: :employee_id)
    add_foreign_key :user_feature_accesses, :users, on_delete: :cascade unless foreign_key_exists?(:user_feature_accesses, :users)
    add_foreign_key :user_feature_accesses, :feature_flags, on_delete: :cascade unless foreign_key_exists?(:user_feature_accesses, :feature_flags)
    
    # Note: Check constraints and NOT NULL constraints are not well-supported in SQLite migrations
    # They can be added later when migrating to PostgreSQL in production
    # For now, we'll focus on foreign key constraints which are the most important for data integrity
  end
end
