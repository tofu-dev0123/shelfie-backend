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

ActiveRecord::Schema[8.1].define(version: 2026_04_12_035523) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "books", force: :cascade do |t|
    t.string "authors", limit: 255, default: [], null: false, array: true
    t.datetime "created_at", null: false
    t.string "isbn", limit: 13, null: false
    t.string "published_date", limit: 10
    t.string "thumbnail_url", limit: 2048
    t.string "title", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.index ["isbn"], name: "index_books_on_isbn", unique: true
  end

  create_table "follows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "followee_id", null: false
    t.bigint "follower_id", null: false
    t.index ["followee_id"], name: "index_follows_on_followee_id"
    t.index ["follower_id", "followee_id"], name: "index_follows_on_follower_id_and_followee_id", unique: true
    t.index ["follower_id"], name: "index_follows_on_follower_id"
    t.check_constraint "follower_id <> followee_id", name: "check_follows_no_self"
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "token", limit: 128, null: false
    t.bigint "user_id", null: false
    t.index ["expires_at"], name: "index_refresh_tokens_on_expires_at"
    t.index ["token"], name: "index_refresh_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "tag_follows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "tag_id", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "tag_id"], name: "index_tag_follows_on_user_id_and_tag_id", unique: true
    t.index ["user_id"], name: "index_tag_follows_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", limit: 50, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "user_book_purchase_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "url", limit: 2048, null: false
    t.bigint "user_book_id", null: false
    t.index ["user_book_id"], name: "index_user_book_purchase_links_on_user_book_id"
  end

  create_table "user_book_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "tag_id", null: false
    t.bigint "user_book_id", null: false
    t.index ["tag_id"], name: "index_user_book_tags_on_tag_id"
    t.index ["user_book_id", "tag_id"], name: "index_user_book_tags_on_user_book_id_and_tag_id", unique: true
  end

  create_table "user_books", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["book_id"], name: "index_user_books_on_book_id"
    t.index ["user_id", "book_id"], name: "index_user_books_on_user_id_and_book_id", unique: true
    t.index ["user_id", "created_at"], name: "index_user_books_on_user_id_and_created_at", order: { created_at: :desc }
  end

  create_table "user_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "url", limit: 2048, null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_user_links_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_key"
    t.text "bio"
    t.string "clerk_user_id", limit: 50, null: false
    t.datetime "created_at", null: false
    t.string "email", limit: 254, null: false
    t.string "nickname", limit: 50, null: false
    t.datetime "updated_at", null: false
    t.string "username", limit: 40, null: false
    t.index ["clerk_user_id"], name: "index_users_on_clerk_user_id", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "want_to_reads", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.datetime "created_at", null: false
    t.bigint "user_id", null: false
    t.index ["book_id"], name: "index_want_to_reads_on_book_id"
    t.index ["user_id", "book_id"], name: "index_want_to_reads_on_user_id_and_book_id", unique: true
    t.index ["user_id"], name: "index_want_to_reads_on_user_id"
  end

  add_foreign_key "follows", "users", column: "followee_id", on_delete: :restrict
  add_foreign_key "follows", "users", column: "follower_id", on_delete: :restrict
  add_foreign_key "refresh_tokens", "users", on_delete: :restrict
  add_foreign_key "tag_follows", "tags", on_delete: :restrict
  add_foreign_key "tag_follows", "users", on_delete: :restrict
  add_foreign_key "user_book_purchase_links", "user_books", on_delete: :restrict
  add_foreign_key "user_book_tags", "tags", on_delete: :restrict
  add_foreign_key "user_book_tags", "user_books", on_delete: :restrict
  add_foreign_key "user_books", "books", on_delete: :restrict
  add_foreign_key "user_books", "users", on_delete: :restrict
  add_foreign_key "user_links", "users", on_delete: :restrict
  add_foreign_key "want_to_reads", "books", on_delete: :restrict
  add_foreign_key "want_to_reads", "users", on_delete: :restrict
end
