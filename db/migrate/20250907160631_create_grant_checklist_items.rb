class CreateGrantChecklistItems < ActiveRecord::Migration[8.0]
  def change
    create_table :grant_checklist_items do |t|
      t.references :grant_application, null: false, foreign_key: true
      t.string :section
      t.string :title
      t.date :due_date
      t.boolean :checked, default: false, null: false
      t.text :notes
      t.string :subbie
      t.boolean :no_subbie, default: false, null: false
      t.string :contract_link

      t.timestamps
    end
  end
end
