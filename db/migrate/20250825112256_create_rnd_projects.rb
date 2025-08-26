class CreateRndProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :rnd_projects do |t|
      t.string :title
      t.text :description
      t.references :client, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.integer :status
      t.text :qualifying_activities
      t.text :technical_challenges

      t.timestamps
    end
  end
end
