class CreateRndExpenditures < ActiveRecord::Migration[8.0]
  def change
    create_table :rnd_expenditures do |t|
      t.references :rnd_project, null: false, foreign_key: true
      t.integer :expenditure_type
      t.decimal :amount
      t.text :description
      t.date :date

      t.timestamps
    end
  end
end
