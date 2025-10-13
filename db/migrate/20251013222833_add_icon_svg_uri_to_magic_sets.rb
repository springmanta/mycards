class AddIconSvgUriToMagicSets < ActiveRecord::Migration[8.0]
  def change
    add_column :magic_sets, :icon_svg_uri, :string
  end
end
