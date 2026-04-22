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

ActiveRecord::Schema[8.0].define(version: 2026_04_21_141340) do
  create_table "campaign_targets", force: :cascade do |t|
    t.integer "campaign_id", null: false
    t.integer "target_id", null: false
    t.text "personalized_subject"
    t.text "personalized_body"
    t.json "custom_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "spam_score"
    t.text "spam_analysis"
    t.index ["campaign_id", "target_id"], name: "index_campaign_targets_on_campaign_id_and_target_id", unique: true
    t.index ["campaign_id"], name: "index_campaign_targets_on_campaign_id"
    t.index ["target_id"], name: "index_campaign_targets_on_target_id"
  end

  create_table "campaigns", force: :cascade do |t|
    t.string "name", null: false
    t.string "target_group", default: "all"
    t.string "sender_email", default: "registration@khas.edu.tr"
    t.string "prompt_type", default: "urgency"
    t.text "scenario_prompt"
    t.text "email_subject"
    t.text "email_body"
    t.string "status", default: "draft"
    t.integer "emails_sent", default: 0
    t.integer "emails_opened", default: 0
    t.integer "links_clicked", default: 0
    t.integer "creds_captured", default: 0
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email_language", default: "English"
    t.boolean "use_custom_scenario", default: false
    t.string "ai_status"
    t.integer "ai_processed_count"
    t.integer "ai_total_count"
    t.index ["status"], name: "index_campaigns_on_status"
  end

  create_table "credentials", force: :cascade do |t|
    t.integer "campaign_id"
    t.integer "target_id"
    t.string "email"
    t.string "password"
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "captured_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id"], name: "index_credentials_on_campaign_id"
    t.index ["target_id"], name: "index_credentials_on_target_id"
  end

  create_table "email_events", force: :cascade do |t|
    t.integer "campaign_id", null: false
    t.integer "target_id", null: false
    t.string "event_type", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "occurred_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id"], name: "index_email_events_on_campaign_id"
    t.index ["event_type"], name: "index_email_events_on_event_type"
    t.index ["target_id"], name: "index_email_events_on_target_id"
  end

  create_table "targets", force: :cascade do |t|
    t.string "email", null: false
    t.string "full_name"
    t.string "group_name"
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_targets_on_email", unique: true
    t.index ["token"], name: "index_targets_on_token", unique: true
  end

  add_foreign_key "campaign_targets", "campaigns"
  add_foreign_key "campaign_targets", "targets"
  add_foreign_key "credentials", "campaigns"
  add_foreign_key "credentials", "targets"
  add_foreign_key "email_events", "campaigns"
  add_foreign_key "email_events", "targets"
end
