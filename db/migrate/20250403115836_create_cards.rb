class CreateCards < ActiveRecord::Migration[8.0]
  def change
    create_table :cards do |t|
      t.string :colors
      t.integer :convertedManaCost
      t.string :name
      t.string :type

      t.timestamps
    end
  end
end
