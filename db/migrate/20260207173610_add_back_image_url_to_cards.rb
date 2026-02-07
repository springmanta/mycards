class AddBackImageUrlToCards < ActiveRecord::Migration[8.0]
  def change
    add_column :cards, :back_image_url, :string
  end
end
