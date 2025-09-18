# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_18_101500) do
  create_table "clients", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "company"
    t.string "sector"
    t.text "funding_needs"
    t.string "phone"
    t.string "website"
    t.text "notes"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "employee_id"
    t.index ["created_at"], name: "index_clients_on_created_at"
    t.index ["employee_id"], name: "index_clients_on_employee_id"
    t.index ["user_id"], name: "index_clients_on_user_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.string "website"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "feature_flags", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.boolean "enabled", default: false
    t.json "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enabled"], name: "index_feature_flags_on_enabled"
    t.index ["name"], name: "index_feature_flags_on_name", unique: true
  end

  create_table "grant_applications", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "stage"
    t.integer "company_id"
    t.integer "grant_competition_id"
    t.boolean "manual_stage_override", default: false, null: false
    t.integer "qualification_cost_pence", default: 0, null: false
    t.index ["company_id"], name: "index_grant_applications_on_company_id"
    t.index ["created_at"], name: "index_grant_applications_on_created_at"
    t.index ["grant_competition_id"], name: "index_grant_applications_on_grant_competition_id"
    t.index ["title"], name: "index_grant_applications_on_title"
    t.index ["user_id"], name: "index_grant_applications_on_user_id"
  end

  create_table "grant_checklist_items", force: :cascade do |t|
    t.integer "grant_application_id", null: false
    t.string "section"
    t.string "title"
    t.date "due_date"
    t.boolean "checked", default: false, null: false
    t.text "notes"
    t.string "technical_qualifier"
    t.boolean "no_technical_qualifier", default: false, null: false
    t.string "contract_link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "review_delivered_on"
    t.string "deal_outcome"
    t.datetime "completed_at"
    t.date "invoice_sent_on"
    t.index ["completed_at"], name: "index_grant_checklist_items_on_completed_at"
    t.index ["deal_outcome"], name: "index_grant_checklist_items_on_deal_outcome"
    t.index ["grant_application_id"], name: "index_grant_checklist_items_on_grant_application_id"
    t.index ["invoice_sent_on"], name: "index_grant_checklist_items_on_invoice_sent_on"
    t.index ["review_delivered_on"], name: "index_grant_checklist_items_on_review_delivered_on"
  end

  create_table "grant_competitions", force: :cascade do |t|
    t.string "grant_name"
    t.datetime "deadline"
    t.string "funding_body"
    t.string "competition_link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "grant_documents", force: :cascade do |t|
    t.string "name"
    t.string "file_path"
    t.string "file_type"
    t.integer "grant_application_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grant_checklist_item_id"
    t.index ["grant_application_id"], name: "index_grant_documents_on_grant_application_id"
    t.index ["grant_checklist_item_id"], name: "index_grant_documents_on_grant_checklist_item_id"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "client_id", null: false
    t.integer "sender_id", null: false
    t.integer "recipient_id", null: false
    t.string "subject"
    t.text "content"
    t.integer "message_type", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_messages_on_client_id"
    t.index ["created_at"], name: "index_messages_on_created_at"
    t.index ["message_type"], name: "index_messages_on_message_type"
    t.index ["recipient_id"], name: "index_messages_on_recipient_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
    t.index ["subject"], name: "index_messages_on_subject"
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title", null: false
    t.text "message", null: false
    t.integer "notification_type", default: 0, null: false
    t.boolean "read", default: false, null: false
    t.datetime "read_at"
    t.string "notifiable_type"
    t.integer "notifiable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_notifications_on_created_at"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["read"], name: "index_notifications_on_read"
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "rnd_claim_expenditures", force: :cascade do |t|
    t.integer "rnd_claim_id", null: false
    t.integer "expenditure_type"
    t.decimal "amount"
    t.text "description"
    t.date "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["amount"], name: "index_rnd_claim_expenditures_on_amount"
    t.index ["date"], name: "index_rnd_claim_expenditures_on_date"
    t.index ["expenditure_type"], name: "index_rnd_claim_expenditures_on_expenditure_type"
    t.index ["rnd_claim_id"], name: "index_rnd_claim_expenditures_on_rnd_claim_id"
  end

  create_table "rnd_claim_projects", force: :cascade do |t|
    t.string "name", null: false
    t.string "qualification_status", default: "qualified", null: false
    t.string "narrative_status", default: "skip", null: false
    t.integer "rnd_claim_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["narrative_status"], name: "index_rnd_claim_projects_on_narrative_status"
    t.index ["qualification_status"], name: "index_rnd_claim_projects_on_qualification_status"
    t.index ["rnd_claim_id", "name"], name: "index_rnd_claim_projects_on_rnd_claim_id_and_name", unique: true
    t.index ["rnd_claim_id"], name: "index_rnd_claim_projects_on_rnd_claim_id"
  end

  create_table "rnd_claims", force: :cascade do |t|
    t.string "title"
    t.date "start_date"
    t.date "end_date"
    t.text "qualifying_activities"
    t.text "technical_challenges"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "company_id"
    t.string "stage"
    t.string "cnf_status", default: "not_claiming"
    t.date "cnf_deadline"
    t.index ["cnf_status"], name: "index_rnd_claims_on_cnf_status"
    t.index ["company_id"], name: "index_rnd_claims_on_company_id"
    t.index ["created_at"], name: "index_rnd_claims_on_created_at"
    t.index ["end_date"], name: "index_rnd_claims_on_end_date"
    t.index ["start_date"], name: "index_rnd_claims_on_start_date"
    t.index ["title"], name: "index_rnd_claims_on_title"
  end

  create_table "user_feature_accesses", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "feature_flag_id", null: false
    t.boolean "enabled", default: false
    t.json "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_flag_id"], name: "index_user_feature_accesses_on_feature_flag_id"
    t.index ["user_id", "feature_flag_id"], name: "index_user_feature_accesses_on_user_id_and_feature_flag_id", unique: true
    t.index ["user_id"], name: "index_user_feature_accesses_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role"
    t.index ["created_at"], name: "index_users_on_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "clients", "users"
  add_foreign_key "clients", "users", column: "employee_id"
  add_foreign_key "grant_applications", "companies"
  add_foreign_key "grant_applications", "grant_competitions"
  add_foreign_key "grant_applications", "users"
  add_foreign_key "grant_checklist_items", "grant_applications"
  add_foreign_key "grant_documents", "grant_applications"
  add_foreign_key "grant_documents", "grant_checklist_items"
  add_foreign_key "messages", "clients"
  add_foreign_key "messages", "users", column: "recipient_id"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "notifications", "users"
  add_foreign_key "rnd_claim_expenditures", "rnd_claims"
  add_foreign_key "rnd_claim_projects", "rnd_claims"
  add_foreign_key "rnd_claims", "companies"
  add_foreign_key "user_feature_accesses", "feature_flags"
  add_foreign_key "user_feature_accesses", "users"
end
