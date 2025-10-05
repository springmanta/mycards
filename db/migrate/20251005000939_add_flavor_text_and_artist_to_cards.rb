class AddFlavorTextAndArtistToCards < ActiveRecord::Migration[8.0]
  def change
    add_column :cards, :flavor_text, :text
    add_column :cards, :artist, :string
  end
end
