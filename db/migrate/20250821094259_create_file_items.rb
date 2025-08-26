class CreateFileItems < ActiveRecord::Migration[8.0]
  def change
    create_table :file_items do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :file_type
      t.integer :file_size
      t.string :category, default: 'personal'
      t.string :original_filename, null: false
      t.string :content_type
      t.string :file_path
      t.string :checksum

      t.timestamps
    end
    
    add_index :file_items, [:user_id, :category]
    add_index :file_items, [:user_id, :file_type]
    add_index :file_items, [:user_id, :created_at]
    add_index :file_items, [:user_id, :name]
  end
end
