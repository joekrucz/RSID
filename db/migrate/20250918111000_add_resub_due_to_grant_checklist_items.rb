class AddResubDueToGrantChecklistItems < ActiveRecord::Migration[7.1]
  def change
    add_column :grant_checklist_items, :resub_due, :string
  end
end


