class AddScryfallIdToCards < ActiveRecord::Migration[8.0]
  def change
    add_column :cards, :scryfall_id, :string
    add_index :cards, :scryfall_id, unique: true
  end
end
