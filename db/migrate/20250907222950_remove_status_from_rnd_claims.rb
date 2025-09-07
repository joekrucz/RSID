class RemoveStatusFromRndClaims < ActiveRecord::Migration[8.0]
  def change
    remove_column :rnd_claims, :status, :integer
  end
end
