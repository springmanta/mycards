class CreateCards < ActiveRecord::Migration[8.0]
  def change
    create_table :cards do |t|
      t.string :name
      t.string :set_name
      t.string :rarity
      t.string :mana_cost
      t.string :type_line
      t.text :oracle_text

      t.timestamps
    end
  end
end
