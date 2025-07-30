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

ActiveRecord::Schema[8.0].define(version: 2025_07_30_054739) do
  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
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

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "antmedia_streams", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "stream_name", null: false
    t.string "stream_key", null: false
    t.string "antmedia_stream_id"
    t.string "piste_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "proto", default: "0", null: false
    t.integer "meeting_id"
  end

  create_table "api_credentials", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "name"
    t.string "api_key"
    t.string "base_url"
    t.string "auth_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "castr_streams", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "Equipe_show_ID"
    t.text "Equipe_class_ID"
    t.text "Start_ingest"
    t.text "Stop_ingest"
    t.text "TimeZone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "stream_id"
    t.string "platform_id"
  end

  create_table "competitions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "name"
    t.string "location"
    t.date "start_date"
    t.date "end_date"
    t.string "source"
    t.string "external_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "logo"
    t.string "timezone"
    t.string "fei_id"
    t.boolean "public_enabled"
    t.boolean "rabbitmq_enabled"
    t.boolean "ftp_enabled"
    t.string "ftp_host"
    t.integer "ftp_port"
    t.string "ftp_user"
    t.string "ftp_password"
    t.string "ftp_path"
    t.boolean "s3_enabled"
    t.string "s3_bucket"
    t.string "s3_region"
    t.string "s3_access_key"
    t.string "s3_secret_key"
    t.string "country"
    t.string "provider"
    t.string "provider_competition_id"
    t.boolean "enable_queue", default: false, null: false
    t.boolean "ffmpeg_quere_enabled"
  end

  create_table "equipe_incident_webhooks", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "equipe_show_id"
    t.integer "equipe_class_id"
    t.integer "hnr"
    t.integer "startnb"
    t.string "ridername"
    t.string "horsename"
    t.integer "phase_course"
    t.integer "round_course"
    t.string "type"
    t.string "timestamp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "show_competitions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.text "show_ID", null: false
    t.text "class_ID", null: false
    t.date "datum", null: false
    t.text "class_num", null: false
    t.text "class_name", null: false
    t.text "Headtitle", null: false
    t.text "subtitle", null: false
    t.text "start_time"
    t.text "arena", null: false
    t.text "Currency", null: false
    t.text "FEI_ID_Class"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "equipe_show_id"
    t.index ["equipe_show_id"], name: "index_show_competitions_on_equipe_show_id"
  end

  create_table "show_horses", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "Equipe_Show_ID", null: false
    t.integer "headnum", null: false
    t.text "horsename", null: false
    t.text "born_year", null: false
    t.text "FEI_ID", null: false
    t.text "Breed", null: false
    t.text "Breeder", null: false
    t.text "Sire", null: false
    t.text "color", null: false
    t.text "SireDam", null: false
    t.text "owner", null: false
    t.text "sex", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["Equipe_Show_ID", "headnum"], name: "index_show_horses_on_Equipe_Show_ID_and_headnum", unique: true
  end

  create_table "show_results", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.text "Equipe_show_ID", null: false
    t.text "Equipe_class_ID", null: false
    t.integer "Ranking", null: false
    t.integer "StartNB"
    t.integer "horse_nb", null: false
    t.text "Ridername", null: false
    t.text "Horsename", null: false
    t.text "Country", null: false
    t.text "results_preview", null: false
    t.text "prize", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "starts_competitions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.text "Equipe_show_ID", null: false
    t.text "Equipe_class_ID", null: false
    t.text "StartNb", null: false
    t.text "horse_nb", null: false
    t.text "Rider_name", null: false
    t.text "Horse_Name", null: false
    t.text "Country", null: false
    t.integer "Equipe_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
