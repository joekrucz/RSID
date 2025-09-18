class AddResourcedSubcontractorToGrantChecklistItems < ActiveRecord::Migration[7.1]
  def change
    add_column :grant_checklist_items, :resourced_subcontractor, :string
  end
end


