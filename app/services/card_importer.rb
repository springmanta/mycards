class CardImporter
  def self.update_card_version(card, scryfall_id)
    scryfall = ScryfallApi.new
    data = scryfall.get_card_by_id(scryfall_id)
    return nil unless data

    # Update card with new version data
    card.update(
      scryfall_id: data["id"],
      photo_url: data.dig("image_uris", "normal"),
      artist: data["artist"],
      rarity: data["rarity"],
      set_name: data["set_name"]
    )

    card
  end

  def self.import_by_id(scryfall_id, quantity = 1)
    scryfall = ScryfallApi.new
    data = scryfall.get_card_by_id(scryfall_id)
    return nil unless data

    # Check if card already exists
    existing_card = Card.find_by(scryfall_id: scryfall_id)

    if existing_card
      # Increment quantity of existing card
      existing_card.quantity += quantity
      existing_card.save
      return existing_card
    else
      # Create new card
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
        oracle_text: data["oracle_text"],
        quantity: quantity
      )
    end
  end
end
