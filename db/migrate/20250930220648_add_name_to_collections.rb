class AddNameToCollections < ActiveRecord::Migration[8.0]
  def change
    add_column :collections, :name, :string, default: "My Collection"
  end
end
