class CreateClients < ActiveRecord::Migration[8.0]
  def change
    create_table :clients do |t|
      t.string :name
      t.string :email
      t.string :company
      t.string :sector
      t.text :funding_needs
      t.string :phone
      t.string :website
      t.text :notes
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
