# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_03_25_231304) do

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_id", null: false
    t.string "resource_type", null: false
    t.integer "author_id"
    t.string "author_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "chat_message_users", force: :cascade do |t|
    t.integer "chat_message_id"
    t.integer "user_id"
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_message_id"], name: "index_chat_message_users_on_chat_message_id"
    t.index ["user_id"], name: "index_chat_message_users_on_user_id"
  end

  create_table "chat_messages", force: :cascade do |t|
    t.integer "chat_id"
    t.integer "author_id"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_chat_messages_on_author_id"
    t.index ["chat_id"], name: "index_chat_messages_on_chat_id"
  end

  create_table "chat_users", force: :cascade do |t|
    t.integer "chat_id"
    t.integer "user_id"
    t.datetime "departed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_chat_users_on_chat_id"
    t.index ["user_id"], name: "index_chat_users_on_user_id"
  end

  create_table "chats", force: :cascade do |t|
    t.integer "creator_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "companies", force: :cascade do |t|
    t.string "name", limit: 256, null: false
    t.string "short_name", limit: 10, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_companies_on_name", unique: true
  end

  create_table "images", force: :cascade do |t|
    t.integer "imageable_id"
    t.string "imageable_type"
    t.string "file_file_name"
    t.string "file_content_type"
    t.integer "file_file_size"
    t.datetime "file_updated_at"
    t.boolean "file_processing", default: false, null: false
    t.text "meta"
    t.string "source"
    t.float "lat"
    t.float "lng"
    t.datetime "taken_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "jobs", force: :cascade do |t|
    t.string "title", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "locatables", force: :cascade do |t|
    t.integer "location_id"
    t.integer "locatable_id"
    t.string "locatable_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["locatable_type", "locatable_id"], name: "index_locatables_on_locatable_type_and_locatable_id"
  end

  create_table "location_beacons", force: :cascade do |t|
    t.integer "location_id"
    t.integer "company_id", null: false
    t.string "mac_address", limit: 12
    t.string "uuid", limit: 32, null: false
    t.integer "major", null: false
    t.integer "minor", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "uuid", "major", "minor"], name: "index_location_beacons_unique_company_identifier", unique: true
  end

  create_table "location_gps", force: :cascade do |t|
    t.integer "location_id"
    t.float "lat", null: false
    t.float "lng", null: false
    t.float "alt", default: 0.0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_location_gps_on_location_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "name", null: false
    t.string "kind"
    t.integer "parent_location_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_location_id", "kind", "name"], name: "index_locations_on_parent_location_id_and_kind_and_name", unique: true
    t.index ["parent_location_id"], name: "index_locations_on_parent_location_id"
  end

  create_table "project_jobs", force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "job_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_project_jobs_on_job_id"
    t.index ["project_id", "job_id"], name: "index_project_jobs_on_project_id_and_job_id", unique: true
    t.index ["project_id"], name: "index_project_jobs_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name", null: false
    t.integer "owner_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "default_password"
    t.index ["owner_id"], name: "index_projects_on_owner_id"
  end

  create_table "roles", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "ownable_id"
    t.string "ownable_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ownable_type", "ownable_id"], name: "index_roles_on_ownable_type_and_ownable_id"
    t.index ["user_id", "ownable_type", "ownable_id"], name: "index_roles_on_user_id_and_ownable_type_and_ownable_id", unique: true
  end

  create_table "team_users", force: :cascade do |t|
    t.integer "user_id"
    t.integer "team_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_team_users_on_team_id"
    t.index ["user_id", "team_id"], name: "index_team_users_on_user_id_and_team_id", unique: true
    t.index ["user_id"], name: "index_team_users_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name"
    t.integer "project_id"
    t.integer "creator_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_teams_on_creator_id"
    t.index ["project_id"], name: "index_teams_on_project_id"
  end

  create_table "user_locations", force: :cascade do |t|
    t.integer "user_id"
    t.integer "location_id"
    t.integer "detectable_id"
    t.string "detectable_type"
    t.float "lat"
    t.float "lng"
    t.float "alt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["detectable_type", "detectable_id"], name: "index_user_locations_on_detectable_type_and_detectable_id"
    t.index ["location_id"], name: "index_user_locations_on_location_id"
    t.index ["user_id"], name: "index_user_locations_on_user_id"
  end

  create_table "user_project_jobs", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "project_id", null: false
    t.integer "job_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_user_project_jobs_on_job_id"
    t.index ["project_id"], name: "index_user_project_jobs_on_project_id"
    t.index ["user_id", "project_id", "job_id"], name: "index_user_project_jobs_on_user_id_and_project_id_and_job_id", unique: true
    t.index ["user_id"], name: "index_user_project_jobs_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.boolean "superuser", default: false, null: false
    t.string "authentication_token"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "first_name"
    t.string "last_name"
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
