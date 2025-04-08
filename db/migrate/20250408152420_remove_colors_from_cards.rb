class RemoveColorsFromCards < ActiveRecord::Migration[8.0]
  def change
    remove_column :cards, :colors, :string
  end
end
