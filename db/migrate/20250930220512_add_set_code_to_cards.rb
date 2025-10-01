class AddSetCodeToCards < ActiveRecord::Migration[8.0]
  def change
    add_column :cards, :set_code, :string
  end
end
