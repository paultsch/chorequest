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

ActiveRecord::Schema[7.1].define(version: 2026_02_22_152000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "children", force: :cascade do |t|
    t.string "name"
    t.integer "age"
    t.bigint "parent_id", null: false
    t.string "pin_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "public_token"
    t.index ["parent_id"], name: "index_children_on_parent_id"
    t.index ["public_token"], name: "index_children_on_public_token", unique: true
  end

  create_table "chore_assignments", force: :cascade do |t|
    t.bigint "child_id", null: false
    t.bigint "chore_id", null: false
    t.string "day"
    t.boolean "completed"
    t.boolean "approved"
    t.string "completion_photo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "scheduled_on"
    t.text "extra_dates"
    t.datetime "completed_at"
    t.index ["child_id", "chore_id", "scheduled_on"], name: "index_chore_assignments_on_child_chore_scheduled_on", unique: true
    t.index ["child_id"], name: "index_chore_assignments_on_child_id"
    t.index ["chore_id"], name: "index_chore_assignments_on_chore_id"
    t.index ["completed_at"], name: "index_chore_assignments_on_completed_at"
    t.index ["scheduled_on"], name: "index_chore_assignments_on_scheduled_on"
  end

  create_table "chores", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.text "definition_of_done"
    t.integer "token_amount"
    t.string "recurrence"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "game_sessions", force: :cascade do |t|
    t.bigint "child_id", null: false
    t.bigint "game_id", null: false
    t.integer "duration_minutes"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_heartbeat"
    t.boolean "stopped_early", default: false, null: false
    t.index ["child_id"], name: "index_game_sessions_on_child_id"
    t.index ["game_id"], name: "index_game_sessions_on_game_id"
    t.index ["last_heartbeat"], name: "index_game_sessions_on_last_heartbeat"
  end

  create_table "games", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "token_per_minute"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "parents", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "password_digest"
    t.boolean "is_admin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "display_name"
    t.string "phone"
    t.boolean "accepted_terms", default: false, null: false
    t.index ["confirmation_token"], name: "index_parents_on_confirmation_token", unique: true
    t.index ["email"], name: "index_parents_on_email", unique: true
    t.index ["reset_password_token"], name: "index_parents_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_parents_on_unlock_token", unique: true
  end

  create_table "token_transactions", force: :cascade do |t|
    t.bigint "child_id", null: false
    t.integer "amount"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["child_id"], name: "index_token_transactions_on_child_id"
  end

  add_foreign_key "children", "parents"
  add_foreign_key "chore_assignments", "children"
  add_foreign_key "chore_assignments", "chores"
  add_foreign_key "game_sessions", "children"
  add_foreign_key "game_sessions", "games"
  add_foreign_key "token_transactions", "children"
end
