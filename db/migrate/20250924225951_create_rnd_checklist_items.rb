class CreateRndChecklistItems < ActiveRecord::Migration[8.0]
  def change
    create_table :rnd_checklist_items do |t|
      t.references :rnd_claim, null: false, foreign_key: true
      t.string :section, null: false
      t.string :title, null: false
      t.date :due_date
      t.boolean :checked, default: false
      t.string :technical_qualifier
      t.boolean :no_technical_qualifier, default: false
      t.string :contract_link
      t.date :review_delivered_on
      t.date :invoice_sent_on
      t.date :invoice_paid_on
      t.string :resourced_subcontractor
      t.string :delivery_folder_link
      t.string :slack_channel_name
      t.string :resub_due
      t.integer :eligibility_check_cost_pence, default: 0
      t.string :deal_outcome
      t.datetime :completed_at
      t.text :notes

      t.timestamps
    end
    
    add_index :rnd_checklist_items, [:rnd_claim_id, :section, :title], unique: true
  end
end
