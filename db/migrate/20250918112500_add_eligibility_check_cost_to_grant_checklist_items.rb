class AddEligibilityCheckCostToGrantChecklistItems < ActiveRecord::Migration[7.1]
  def change
    add_column :grant_checklist_items, :eligibility_check_cost_pence, :integer, default: 0, null: false
  end
end


