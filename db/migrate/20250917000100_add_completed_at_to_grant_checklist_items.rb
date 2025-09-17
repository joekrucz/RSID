class AddCompletedAtToGrantChecklistItems < ActiveRecord::Migration[8.0]
  def up
    add_column :grant_checklist_items, :completed_at, :datetime
    add_index :grant_checklist_items, :completed_at
  end

  def down
    remove_index :grant_checklist_items, :completed_at
    remove_column :grant_checklist_items, :completed_at
  end
end


