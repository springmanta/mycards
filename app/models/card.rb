class Card < ApplicationRecord
  
  def self.from_scryfall(name)
    data = ScryfallApi.new.search_card_by_name(name)
    return nil unless data

    Card.create(
      scryfall_id: data["id"],
      name: data["name"],
      mana_cost: data["mana_cost"],
      cmc: data["cmc"],
      colors: data["colors"],
      card_type: data["type_line"],
      photo_url: data.dig("image_uris", "normal"),
      artist: data["artist"]
    )
  end
end
