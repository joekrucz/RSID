class CreateGrantApplications < ActiveRecord::Migration[8.0]
  def change
    create_table :grant_applications do |t|
      t.string :title
      t.text :description
      t.integer :status
      t.datetime :deadline
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
