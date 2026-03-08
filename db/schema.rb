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

ActiveRecord::Schema[7.1].define(version: 2026_03_08_100000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.string "message_id", null: false
    t.string "message_checksum", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_audits", force: :cascade do |t|
    t.bigint "admin_id", null: false
    t.string "action"
    t.string "auditable_type"
    t.bigint "auditable_id"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_admin_audits_on_admin_id"
    t.index ["auditable_type", "auditable_id"], name: "index_admin_audits_on_auditable_type_and_auditable_id"
  end

  create_table "admins", force: :cascade do |t|
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
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "children", force: :cascade do |t|
    t.string "name"
    t.bigint "parent_id", null: false
    t.string "pin_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "public_token"
    t.date "birthday"
    t.index ["parent_id"], name: "index_children_on_parent_id"
    t.index ["public_token"], name: "index_children_on_public_token", unique: true
  end

  create_table "chore_assignments", force: :cascade do |t|
    t.bigint "child_id", null: false
    t.bigint "chore_id", null: false
    t.string "day"
    t.boolean "completed"
    t.boolean "approved"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "scheduled_on"
    t.text "extra_dates"
    t.datetime "completed_at"
    t.boolean "require_photo", default: false, null: false
    t.index ["child_id", "chore_id", "scheduled_on"], name: "index_chore_assignments_on_child_chore_scheduled_on", unique: true
    t.index ["child_id"], name: "index_chore_assignments_on_child_id"
    t.index ["chore_id"], name: "index_chore_assignments_on_chore_id"
    t.index ["completed_at"], name: "index_chore_assignments_on_completed_at"
    t.index ["scheduled_on"], name: "index_chore_assignments_on_scheduled_on"
  end

  create_table "chore_attempts", force: :cascade do |t|
    t.bigint "chore_assignment_id", null: false
    t.string "status", default: "pending", null: false
    t.text "parent_note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ai_verdict"
    t.text "ai_message"
    t.datetime "ai_analyzed_at"
    t.bigint "chore_task_id"
    t.index ["chore_assignment_id", "status"], name: "index_chore_attempts_on_chore_assignment_id_and_status"
    t.index ["chore_assignment_id"], name: "index_chore_attempts_on_chore_assignment_id"
    t.index ["chore_task_id"], name: "index_chore_attempts_on_chore_task_id"
  end

  create_table "chore_tasks", force: :cascade do |t|
    t.bigint "chore_id", null: false
    t.string "title", null: false
    t.integer "position", default: 0, null: false
    t.boolean "photo_required", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chore_id", "position"], name: "index_chore_tasks_on_chore_id_and_position"
    t.index ["chore_id"], name: "index_chore_tasks_on_chore_id"
  end

  create_table "chores", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.text "definition_of_done"
    t.integer "token_amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "parent_id", null: false
    t.integer "frequency_days"
    t.index ["parent_id"], name: "index_chores_on_parent_id"
  end

  create_table "game_scores", force: :cascade do |t|
    t.bigint "child_id", null: false
    t.bigint "game_id", null: false
    t.integer "score", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["child_id"], name: "index_game_scores_on_child_id"
    t.index ["game_id", "score"], name: "index_game_scores_on_game_id_and_score"
    t.index ["game_id"], name: "index_game_scores_on_game_id"
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
    t.string "first_name"
    t.string "last_name"
    t.boolean "accept_terms", default: false, null: false
    t.datetime "archived_at"
    t.text "rue_history"
    t.string "plan_tier", default: "free", null: false
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.string "subscription_status"
    t.datetime "trial_ends_at"
    t.index ["archived_at"], name: "index_parents_on_archived_at"
    t.index ["confirmation_token"], name: "index_parents_on_confirmation_token", unique: true
    t.index ["email"], name: "index_parents_on_email", unique: true
    t.index ["reset_password_token"], name: "index_parents_on_reset_password_token", unique: true
    t.index ["stripe_customer_id"], name: "index_parents_on_stripe_customer_id", unique: true
    t.index ["stripe_subscription_id"], name: "index_parents_on_stripe_subscription_id", unique: true
    t.index ["unlock_token"], name: "index_parents_on_unlock_token", unique: true
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.bigint "parent_id"
    t.bigint "child_id"
    t.string "endpoint", null: false
    t.string "p256dh", null: false
    t.string "auth", null: false
    t.string "platform", default: "web", null: false
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["child_id"], name: "index_push_subscriptions_on_child_id"
    t.index ["endpoint"], name: "index_push_subscriptions_on_endpoint", unique: true
    t.index ["parent_id"], name: "index_push_subscriptions_on_parent_id"
  end

  create_table "school_messages", force: :cascade do |t|
    t.bigint "parent_id", null: false
    t.string "subject"
    t.text "raw_body"
    t.string "from_address"
    t.string "category"
    t.string "child_name"
    t.text "summary"
    t.text "action_item"
    t.date "deadline"
    t.boolean "actioned", default: false
    t.boolean "needs_attention", default: true
    t.string "parse_status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id", "actioned"], name: "index_school_messages_on_parent_id_and_actioned"
    t.index ["parent_id", "needs_attention"], name: "index_school_messages_on_parent_id_and_needs_attention"
    t.index ["parent_id"], name: "index_school_messages_on_parent_id"
  end

  create_table "token_transactions", force: :cascade do |t|
    t.bigint "child_id", null: false
    t.integer "amount"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["child_id"], name: "index_token_transactions_on_child_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "children", "parents"
  add_foreign_key "chore_assignments", "children"
  add_foreign_key "chore_assignments", "chores"
  add_foreign_key "chore_attempts", "chore_assignments"
  add_foreign_key "chore_attempts", "chore_tasks"
  add_foreign_key "chore_tasks", "chores"
  add_foreign_key "chores", "parents"
  add_foreign_key "game_scores", "children"
  add_foreign_key "game_scores", "games"
  add_foreign_key "game_sessions", "children"
  add_foreign_key "game_sessions", "games"
  add_foreign_key "push_subscriptions", "children"
  add_foreign_key "push_subscriptions", "parents"
  add_foreign_key "school_messages", "parents"
  add_foreign_key "token_transactions", "children"
end
