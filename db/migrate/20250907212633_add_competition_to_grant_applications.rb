class AddCompetitionToGrantApplications < ActiveRecord::Migration[8.0]
  def change
    add_reference :grant_applications, :grant_competition, null: true, foreign_key: true
  end
end
