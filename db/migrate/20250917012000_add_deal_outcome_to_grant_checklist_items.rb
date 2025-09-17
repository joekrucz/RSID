class AddDealOutcomeToGrantChecklistItems < ActiveRecord::Migration[8.0]
  def change
    add_column :grant_checklist_items, :deal_outcome, :string
    add_index :grant_checklist_items, :deal_outcome
  end
end


