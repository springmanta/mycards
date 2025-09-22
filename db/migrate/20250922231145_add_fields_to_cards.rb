class AddFieldsToCards < ActiveRecord::Migration[8.0]
  def change
    add_column :cards, :power, :string
    add_column :cards, :toughness, :string
    add_column :cards, :image_url, :string
  end
end
