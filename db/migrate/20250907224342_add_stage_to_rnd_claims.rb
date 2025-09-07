class AddStageToRndClaims < ActiveRecord::Migration[8.0]
  def change
    add_column :rnd_claims, :stage, :string
  end
end
