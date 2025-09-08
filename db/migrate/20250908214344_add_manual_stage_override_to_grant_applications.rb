class AddManualStageOverrideToGrantApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :grant_applications, :manual_stage_override, :boolean, default: false, null: false
  end
end
