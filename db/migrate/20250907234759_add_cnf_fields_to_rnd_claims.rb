class AddCnfFieldsToRndClaims < ActiveRecord::Migration[8.0]
  def change
    add_column :rnd_claims, :cnf_status, :string, default: 'not_claiming'
    add_column :rnd_claims, :cnf_deadline, :date
    add_index :rnd_claims, :cnf_status
  end
end
