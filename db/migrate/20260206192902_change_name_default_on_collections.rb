class ChangeNameDefaultOnCollections < ActiveRecord::Migration[8.0]
  def change
    change_column_default :collections, :name, from: "My Collection", to: nil
  end
end
