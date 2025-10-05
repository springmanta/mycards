class AddPricingToCards < ActiveRecord::Migration[8.0]
  def change
    add_column :cards, :tcgplayer_price, :decimal, precision: 8, scale: 2
    add_column :cards, :cardmarket_price, :decimal, precision: 8, scale: 2
    add_column :cards, :prices_updated_at, :datetime
  end
end
