class AddCompanyToRndClaims < ActiveRecord::Migration[8.0]
  def change
    add_reference :rnd_claims, :company, null: true, foreign_key: true
  end
end
