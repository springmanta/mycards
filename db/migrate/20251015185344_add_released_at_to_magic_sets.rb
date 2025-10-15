class AddReleasedAtToMagicSets < ActiveRecord::Migration[8.0]
  def change
    add_column :magic_sets, :released_at, :date
  end
end
