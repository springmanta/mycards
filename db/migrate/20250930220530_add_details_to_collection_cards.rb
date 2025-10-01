class AddDetailsToCollectionCards < ActiveRecord::Migration[8.0]
  def change
    add_column :collection_cards, :quantity, :integer, default: 1, null: false
    add_column :collection_cards, :condition, :string, default: "near_mint"
    add_column :collection_cards, :foil, :boolean, default: false, null: false
    add_column :collection_cards, :price_paid, :decimal, precision: 8, scale: 2
    add_column :collection_cards, :acquired_at, :date
  end
end
