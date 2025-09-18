class AddCompletedAtToGrantChecklistItems < ActiveRecord::Migration[7.1]
  def change
    add_column :grant_checklist_items, :completed_at, :datetime
    add_index :grant_checklist_items, :completed_at
  end
end


