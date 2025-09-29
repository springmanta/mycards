class CreateCollectionCards < ActiveRecord::Migration[8.0]
  def change
    create_table :collection_cards do |t|
      t.timestamps
    end
  end
end
