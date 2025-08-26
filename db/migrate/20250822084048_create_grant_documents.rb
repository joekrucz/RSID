class CreateGrantDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :grant_documents do |t|
      t.string :name
      t.string :file_path
      t.string :file_type
      t.references :grant_application, null: false, foreign_key: true

      t.timestamps
    end
  end
end
