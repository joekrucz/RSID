class CreateTodos < ActiveRecord::Migration[8.0]
  def change
    create_table :todos do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.boolean :completed
      t.string :priority
      t.date :due_date

      t.timestamps
    end
  end
end
