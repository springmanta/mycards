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

ActiveRecord::Schema[8.0].define(version: 2025_04_08_153129) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "cards", force: :cascade do |t|
    t.integer "convertedManaCost"
    t.string "name"
    t.string "card_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "photo_url"
    t.string "scryfall_id"
    t.string "mana_cost"
    t.float "cmc"
    t.string "color_identity", default: [], array: true
    t.string "rarity"
    t.string "set_name"
    t.text "oracle_text"
    t.string "layout"
    t.string "image_url"
    t.string "collector_number"
    t.boolean "foil"
    t.boolean "nonfoil"
    t.boolean "promo"
    t.boolean "digital"
    t.jsonb "full_json"
    t.string "artist"
    t.string "colors", default: [], array: true
    t.index ["scryfall_id"], name: "index_cards_on_scryfall_id", unique: true
  end
end
