class CreateCardTags < ActiveRecord::Migration[8.0]
  def change
    create_table :card_tags do |t|
      t.timestamps
    end
  end
end
