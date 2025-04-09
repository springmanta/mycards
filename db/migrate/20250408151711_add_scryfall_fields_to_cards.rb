class AddScryfallFieldsToCards < ActiveRecord::Migration[8.0]
  def change
    add_column :cards, :scryfall_id, :string
    add_column :cards, :mana_cost, :string
    add_column :cards, :cmc, :float
    add_column :cards, :color_identity, :string, array: true, default: []
    add_column :cards, :rarity, :string
    add_column :cards, :set_name, :string
    add_column :cards, :oracle_text, :text
    add_column :cards, :layout, :string
    add_column :cards, :image_url, :string
    add_column :cards, :collector_number, :string
    add_column :cards, :foil, :boolean
    add_column :cards, :nonfoil, :boolean
    add_column :cards, :promo, :boolean
    add_column :cards, :digital, :boolean
    add_column :cards, :full_json, :jsonb
    add_column :cards, :artist, :string
  end
end
