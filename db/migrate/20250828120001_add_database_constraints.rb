class AddDatabaseConstraints < ActiveRecord::Migration[8.0]
  def change
    # Add foreign key constraints
    add_foreign_key :notes, :users, on_delete: :cascade
    add_foreign_key :todos, :users, on_delete: :cascade
    add_foreign_key :messages, :users, column: :sender_id, on_delete: :cascade
    add_foreign_key :messages, :users, column: :recipient_id, on_delete: :cascade
    add_foreign_key :messages, :clients, on_delete: :cascade
    add_foreign_key :rnd_projects, :clients, on_delete: :cascade
    add_foreign_key :rnd_expenditures, :rnd_projects, on_delete: :cascade
    add_foreign_key :grant_applications, :users, on_delete: :cascade
    add_foreign_key :grant_documents, :grant_applications, on_delete: :cascade
    add_foreign_key :file_items, :users, on_delete: :cascade
    add_foreign_key :notifications, :users, on_delete: :cascade
    add_foreign_key :clients, :users, on_delete: :cascade
    add_foreign_key :clients, :users, column: :employee_id, on_delete: :nullify
    add_foreign_key :user_feature_accesses, :users, on_delete: :cascade
    add_foreign_key :user_feature_accesses, :feature_flags, on_delete: :cascade
    
    # Add check constraints
    execute "ALTER TABLE todos ADD CONSTRAINT check_priority CHECK (priority IN ('low', 'medium', 'high'))"
    execute "ALTER TABLE todos ADD CONSTRAINT check_completed CHECK (completed IN (0, 1))"
    execute "ALTER TABLE rnd_projects ADD CONSTRAINT check_status CHECK (status IN (0, 1, 2, 3, 4))"
    execute "ALTER TABLE grant_applications ADD CONSTRAINT check_grant_status CHECK (status IN (0, 1, 2, 3, 4))"
    execute "ALTER TABLE messages ADD CONSTRAINT check_message_type CHECK (message_type IN (0, 1))"
    execute "ALTER TABLE users ADD CONSTRAINT check_role CHECK (role IN (0, 1, 2))"
    execute "ALTER TABLE notifications ADD CONSTRAINT check_notification_type CHECK (notification_type IN (0, 1, 2, 3, 4, 5))"
    execute "ALTER TABLE notifications ADD CONSTRAINT check_read CHECK (read IN (0, 1))"
    
    # Add not null constraints where missing
    change_column_null :users, :name, false
    change_column_null :users, :email, false
    change_column_null :users, :role, false
    change_column_null :notes, :title, false
    change_column_null :notes, :content, false
    change_column_null :todos, :title, false
    change_column_null :messages, :subject, false
    change_column_null :messages, :content, false
    change_column_null :rnd_projects, :title, false
    change_column_null :rnd_projects, :description, false
    change_column_null :grant_applications, :title, false
    change_column_null :file_items, :name, false
    change_column_null :notifications, :title, false
    change_column_null :notifications, :message, false
  end
end
