class AddEmployeeIdToClients < ActiveRecord::Migration[8.0]
  def change
    add_reference :clients, :employee, null: true, foreign_key: { to_table: :users }
  end
end
