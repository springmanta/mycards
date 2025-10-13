class CreateMagicSets < ActiveRecord::Migration[8.0]
  def change
    create_table :magic_sets do |t|
      t.string :code
      t.string :name

      t.timestamps
    end
  end
end
