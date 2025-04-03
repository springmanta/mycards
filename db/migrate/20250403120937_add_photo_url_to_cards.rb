class AddPhotoUrlToCards < ActiveRecord::Migration[8.0]
  def change
    add_column :cards, :photo_url, :string
  end
end
