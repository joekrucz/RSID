class AddQualificationCostToGrantApplications < ActiveRecord::Migration[7.1]
  def change
    add_column :grant_applications, :qualification_cost_pence, :integer, default: 0, null: false
  end
end


