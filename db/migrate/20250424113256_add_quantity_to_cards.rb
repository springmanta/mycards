class AddQuantityToCards < ActiveRecord::Migration[8.0]
  def change
    add_column :cards, :quantity, :integer, default: 1, null: false
  end
end
