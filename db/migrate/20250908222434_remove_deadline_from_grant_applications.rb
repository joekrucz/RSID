class RemoveDeadlineFromGrantApplications < ActiveRecord::Migration[8.0]
  def change
    remove_column :grant_applications, :deadline, :datetime
  end
end
