class AddReviewDeliveredOnToGrantChecklistItems < ActiveRecord::Migration[8.0]
  def change
    add_column :grant_checklist_items, :review_delivered_on, :date
    add_index :grant_checklist_items, :review_delivered_on
  end
end


