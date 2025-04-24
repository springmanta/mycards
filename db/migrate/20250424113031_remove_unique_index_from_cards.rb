class RemoveUniqueIndexFromCards < ActiveRecord::Migration[8.0]
  def change
    remove_index :cards, :scryfall_id, unique: true
    add_index :cards, :scryfall_id, unique: false
  end
end
