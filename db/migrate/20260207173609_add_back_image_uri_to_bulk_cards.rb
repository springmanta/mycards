class AddBackImageUriToBulkCards < ActiveRecord::Migration[8.0]
  def change
    add_column :bulk_cards, :back_image_uri, :string
  end
end
