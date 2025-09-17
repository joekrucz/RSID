class AddCompletedAtToGrantChecklistItems < ActiveRecord::Migration[8.0]
  def change
    add_column :grant_checklist_items, :completed_at, :datetime
    add_index :grant_checklist_items, :completed_at
  end
end


