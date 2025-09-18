class AddInvoicePaidOnToGrantChecklistItems < ActiveRecord::Migration[7.1]
  def change
    add_column :grant_checklist_items, :invoice_paid_on, :date
    add_index :grant_checklist_items, :invoice_paid_on
  end
end


