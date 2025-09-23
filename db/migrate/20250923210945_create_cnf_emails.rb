class CreateCnfEmails < ActiveRecord::Migration[8.0]
  def change
    create_table :cnf_emails do |t|
      t.references :rnd_claim, null: false, foreign_key: true
      t.string :email_slot, null: false
      t.string :template_type, null: false
      t.string :status, default: 'to_be_sent'
      t.datetime :sent_at
      t.text :subject
      t.text :body
      t.string :recipient_email
      t.string :sender_email, default: 'customersuccess@granttree.co.uk'

      t.timestamps
    end

    add_index :cnf_emails, [:rnd_claim_id, :email_slot], unique: true
    add_index :cnf_emails, :status
  end
end
