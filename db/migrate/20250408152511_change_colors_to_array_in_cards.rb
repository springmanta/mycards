class ChangeColorsToArrayInCards < ActiveRecord::Migration[8.0]
  def change
    change_column :cards, :colors, :string, array: true, default: []
  end
end
