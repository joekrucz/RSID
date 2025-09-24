class AddCnfSubmissionDateToRndClaims < ActiveRecord::Migration[8.0]
  def change
    add_column :rnd_claims, :cnf_submission_date, :date
  end
end
