class AddStageToGrantApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :grant_applications, :stage, :integer
  end
end
