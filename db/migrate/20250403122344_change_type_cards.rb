class ChangeTypeCards < ActiveRecord::Migration[8.0]
  def change
    rename_column :cards, :type, :card_type
  end
end
