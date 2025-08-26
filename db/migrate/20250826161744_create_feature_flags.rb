class CreateFeatureFlags < ActiveRecord::Migration[8.0]
  def change
    create_table :feature_flags do |t|
      t.string :name, null: false, index: { unique: true }
      t.text :description
      t.boolean :enabled, default: false
      t.json :settings, default: {}
      t.timestamps
    end
  end
end
