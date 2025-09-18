class RenameSubbieToTechnicalQualifierInGrantChecklistItems < ActiveRecord::Migration[7.1]
  def change
    # Rename columns to reflect new terminology
    rename_column :grant_checklist_items, :subbie, :technical_qualifier
    rename_column :grant_checklist_items, :no_subbie, :no_technical_qualifier
  end
end


