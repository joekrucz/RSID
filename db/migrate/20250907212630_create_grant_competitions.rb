class CreateGrantCompetitions < ActiveRecord::Migration[8.0]
  def change
    create_table :grant_competitions do |t|
      t.string :grant_name
      t.datetime :deadline
      t.string :funding_body
      t.string :competition_link

      t.timestamps
    end
  end
end
