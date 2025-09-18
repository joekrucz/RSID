class AddSetupFieldsToGrantChecklistItems < ActiveRecord::Migration[7.1]
  def change
    add_column :grant_checklist_items, :delivery_folder_link, :string
    add_column :grant_checklist_items, :slack_channel_name, :string
  end
end


