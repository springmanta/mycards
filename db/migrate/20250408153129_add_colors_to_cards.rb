class AddColorsToCards < ActiveRecord::Migration[8.0]
  def change
    add_column :cards, :colors, :string, array: true, default: []
  end
end
