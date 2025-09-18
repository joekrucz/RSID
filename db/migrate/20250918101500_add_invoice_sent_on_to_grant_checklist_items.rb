class AddInvoiceSentOnToGrantChecklistItems < ActiveRecord::Migration[7.1]
  def change
    add_column :grant_checklist_items, :invoice_sent_on, :date
    add_index :grant_checklist_items, :invoice_sent_on
  end
end


