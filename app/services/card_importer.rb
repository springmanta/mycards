class CardImporter
  def self.import_by_name(name)
    scryfall = ScryfallApi.new
    data = scryfall.search_cards(name)
    return nil unless data

    Card.create(
      scryfall_id: data["id"],
      name: data["name"],
      mana_cost: data["mana_cost"],
      cmc: data["cmc"],
      colors: data["colors"],
      card_type: data["type_line"],
      photo_url: data.dig("image_uris", "normal"),
      artist: data["artist"],
      rarity: data["rarity"],
      set_name: data["set_name"],
      oracle_text: data["oracle_text"]
    )
  end
end
