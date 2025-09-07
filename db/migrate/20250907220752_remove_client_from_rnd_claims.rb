class RemoveClientFromRndClaims < ActiveRecord::Migration[8.0]
  def change
    remove_reference :rnd_claims, :client, null: false, foreign_key: true
  end
end
