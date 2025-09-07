class CreateRndClaimProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :rnd_claim_projects do |t|
      t.string :name, null: false
      t.string :qualification_status, null: false, default: 'qualified'
      t.string :narrative_status, null: false, default: 'skip'
      t.references :rnd_claim, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :rnd_claim_projects, :qualification_status
    add_index :rnd_claim_projects, :narrative_status
    add_index :rnd_claim_projects, [:rnd_claim_id, :name], unique: true
  end
end
