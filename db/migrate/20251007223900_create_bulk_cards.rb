class CreateBulkCards < ActiveRecord::Migration[8.0]
  def change
    create_table :bulk_cards do |t|
      t.string :scryfall_id, null: false
      t.string :name, null: false
      t.string :set_code
      t.string :collector_number
      t.decimal :eur_price, precision: 10, scale: 2
      t.string :image_uri
      t.string :rarity
      t.string :type_line
      t.string :mana_cost
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :bulk_cards, :scryfall_id, unique: true
    add_index :bulk_cards, :name
    add_index :bulk_cards, :set_code
    add_index :bulk_cards, "lower(name)", name: "index_bulk_cards_on_lower_name"
  end
end
