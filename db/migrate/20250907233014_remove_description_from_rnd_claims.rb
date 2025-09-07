class RemoveDescriptionFromRndClaims < ActiveRecord::Migration[8.0]
  def change
    remove_column :rnd_claims, :description, :text
  end
end
