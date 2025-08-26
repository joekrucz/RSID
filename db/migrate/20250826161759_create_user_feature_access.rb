class CreateUserFeatureAccess < ActiveRecord::Migration[8.0]
  def change
    create_table :user_feature_accesses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :feature_flag, null: false, foreign_key: true
      t.boolean :enabled, default: false
      t.json :settings, default: {}
      t.timestamps
      
      t.index [:user_id, :feature_flag_id], unique: true
    end
  end
end
