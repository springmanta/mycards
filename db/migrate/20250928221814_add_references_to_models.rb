class AddReferencesToModels < ActiveRecord::Migration[8.0]
  def change
    add_reference :collections, :user, null: false, foreign_key: true

    add_reference :collection_cards, :collection, null: false, foreign_key: true
    add_reference :collection_cards, :card, null: false, foreign_key: true

    add_reference :card_tags, :card, null: false, foreign_key: true
    add_reference :card_tags, :tag, null: false, foreign_key: true
  end
end
