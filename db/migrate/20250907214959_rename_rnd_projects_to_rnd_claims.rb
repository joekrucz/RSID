class RenameRndProjectsToRndClaims < ActiveRecord::Migration[8.0]
  def change
    # Rename tables
    rename_table :rnd_projects, :rnd_claims
    rename_table :rnd_expenditures, :rnd_claim_expenditures
    
    # Update foreign key references
    rename_column :rnd_claim_expenditures, :rnd_project_id, :rnd_claim_id
  end
end
