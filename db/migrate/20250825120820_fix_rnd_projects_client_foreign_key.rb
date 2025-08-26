class FixRndProjectsClientForeignKey < ActiveRecord::Migration[8.0]
  def change
    # Remove the incorrect foreign key to clients table
    remove_foreign_key :rnd_projects, :clients, if_exists: true
    
    # Add the correct foreign key to users table
    add_foreign_key :rnd_projects, :users, column: :client_id
  end
end
