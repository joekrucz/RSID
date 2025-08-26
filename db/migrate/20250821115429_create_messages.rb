class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.references :client, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.string :subject
      t.text :content
      t.integer :message_type, default: 0

      t.timestamps
    end
  end
end
