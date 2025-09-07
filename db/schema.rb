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

ActiveRecord::Schema[8.0].define(version: 2025_09_07_185226) do
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

  create_table "file_items", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "file_type"
    t.integer "file_size"
    t.string "category", default: "personal"
    t.string "original_filename", null: false
    t.string "content_type"
    t.string "file_path"
    t.string "checksum"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_file_items_on_category"
    t.index ["created_at"], name: "index_file_items_on_created_at"
    t.index ["file_type"], name: "index_file_items_on_file_type"
    t.index ["name"], name: "index_file_items_on_name"
    t.index ["user_id", "category"], name: "index_file_items_on_user_id_and_category"
    t.index ["user_id", "created_at"], name: "index_file_items_on_user_id_and_created_at"
    t.index ["user_id", "file_type"], name: "index_file_items_on_user_id_and_file_type"
    t.index ["user_id", "name"], name: "index_file_items_on_user_id_and_name"
    t.index ["user_id"], name: "index_file_items_on_user_id"
  end

  create_table "grant_applications", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "deadline"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "stage"
    t.integer "company_id"
    t.index ["company_id"], name: "index_grant_applications_on_company_id"
    t.index ["created_at"], name: "index_grant_applications_on_created_at"
    t.index ["deadline"], name: "index_grant_applications_on_deadline"
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
    t.string "subbie"
    t.boolean "no_subbie", default: false, null: false
    t.string "contract_link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["grant_application_id"], name: "index_grant_checklist_items_on_grant_application_id"
  end

  create_table "grant_documents", force: :cascade do |t|
    t.string "name"
    t.string "file_path"
    t.string "file_type"
    t.integer "grant_application_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["grant_application_id"], name: "index_grant_documents_on_grant_application_id"
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

  create_table "notes", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_notes_on_created_at"
    t.index ["title"], name: "index_notes_on_title"
    t.index ["updated_at"], name: "index_notes_on_updated_at"
    t.index ["user_id"], name: "index_notes_on_user_id"
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

  create_table "rnd_expenditures", force: :cascade do |t|
    t.integer "rnd_project_id", null: false
    t.integer "expenditure_type"
    t.decimal "amount"
    t.text "description"
    t.date "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["amount"], name: "index_rnd_expenditures_on_amount"
    t.index ["date"], name: "index_rnd_expenditures_on_date"
    t.index ["expenditure_type"], name: "index_rnd_expenditures_on_expenditure_type"
    t.index ["rnd_project_id"], name: "index_rnd_expenditures_on_rnd_project_id"
  end

  create_table "rnd_projects", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "client_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.integer "status"
    t.text "qualifying_activities"
    t.text "technical_challenges"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_rnd_projects_on_client_id"
    t.index ["created_at"], name: "index_rnd_projects_on_created_at"
    t.index ["end_date"], name: "index_rnd_projects_on_end_date"
    t.index ["start_date"], name: "index_rnd_projects_on_start_date"
    t.index ["status"], name: "index_rnd_projects_on_status"
    t.index ["title"], name: "index_rnd_projects_on_title"
  end

  create_table "todos", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title"
    t.text "description"
    t.boolean "completed"
    t.string "priority"
    t.date "due_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["completed"], name: "index_todos_on_completed"
    t.index ["created_at"], name: "index_todos_on_created_at"
    t.index ["due_date"], name: "index_todos_on_due_date"
    t.index ["priority"], name: "index_todos_on_priority"
    t.index ["title"], name: "index_todos_on_title"
    t.index ["user_id"], name: "index_todos_on_user_id"
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
  add_foreign_key "file_items", "users"
  add_foreign_key "grant_applications", "companies"
  add_foreign_key "grant_applications", "users"
  add_foreign_key "grant_checklist_items", "grant_applications"
  add_foreign_key "grant_documents", "grant_applications"
  add_foreign_key "messages", "clients"
  add_foreign_key "messages", "users", column: "recipient_id"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "notes", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "rnd_expenditures", "rnd_projects"
  add_foreign_key "rnd_projects", "clients", on_delete: :cascade
  add_foreign_key "rnd_projects", "users", column: "client_id"
  add_foreign_key "todos", "users"
  add_foreign_key "user_feature_accesses", "feature_flags"
  add_foreign_key "user_feature_accesses", "users"
end
