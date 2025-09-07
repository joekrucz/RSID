class RemoveStatusFromGrantApplications < ActiveRecord::Migration[8.0]
  def change
    remove_column :grant_applications, :status, :integer
  end
end
