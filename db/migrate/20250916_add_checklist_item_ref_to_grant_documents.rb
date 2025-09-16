class AddChecklistItemRefToGrantDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :grant_documents, :grant_checklist_item_id, :integer
    add_index :grant_documents, :grant_checklist_item_id
    add_foreign_key :grant_documents, :grant_checklist_items
  end
end


