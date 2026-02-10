class ImportsController < ApplicationController
  def new
  end

  def create
    text = params[:card_list]&.strip

    if text.blank?
      redirect_to new_import_path, alert: "Please paste a card list"
      return
    end

    lines = text.split("\n").map(&:strip).reject(&:blank?)

    # Create or find "Imported" collection
    base_name = "Import"
    existing_count = Current.user.collections.where("name LIKE ?", "#{base_name}%").count
    collection_name = existing_count == 0 ? base_name : "#{base_name} #{existing_count + 1}"
    @collection = Current.user.collections.create!(name: collection_name)

    @results = { matched: [], unmatched: [], duplicates: [] }

    lines.each do |line|
      parsed = parse_line(line)
      unless parsed
        @results[:unmatched] << { line: line, parsed: nil }
        next
      end

      bulk_card = find_bulk_card(parsed)

      if bulk_card
        card = Card.find_or_initialize_by(scryfall_id: bulk_card.scryfall_id)
        card.assign_attributes(
          name: bulk_card.name,
          set_name: bulk_card.magic_set&.name,
          set_code: bulk_card.set_code,
          rarity: bulk_card.rarity,
          mana_cost: bulk_card.mana_cost,
          colors: Array(bulk_card.metadata["colors"]).join(","),
          type_line: bulk_card.type_line,
          oracle_text: bulk_card.metadata["oracle_text"],
          image_url: bulk_card.image_uri,
          back_image_url: bulk_card.back_image_uri,
          cardmarket_price: bulk_card.eur_price,
          prices_updated_at: Time.current
        )
        card.save!

        existing = CollectionCard.find_by(collection: @collection, card: card)
        if existing
          existing.update!(quantity: existing.quantity + parsed[:quantity])
          @results[:duplicates] << { line: line, card: card, quantity: parsed[:quantity] }
        else
          CollectionCard.create!(
            collection: @collection,
            card: card,
            quantity: parsed[:quantity],
            foil: parsed[:foil]
          )
          @results[:matched] << { line: line, card: card, quantity: parsed[:quantity] }
        end
      else
        @results[:unmatched] << { line: line, parsed: parsed }
      end
    end

    redirect_to collection_path(@collection), notice: "Imported #{@results[:matched].size + @results[:duplicates].size} cards. Created collection '#{@collection.name}'"
  end

  private

  # Parses: 1 Lightning Bolt (M21) 197 *F*
  def parse_line(line)
    # Format 1: Moxfield - 1 Lightning Bolt (M21) 197 *F*
    if (match = line.match(/^(\d+)\s+(.+?)\s+\((\w+)\)\s+([\w\d]+)\s*(\*F\*)?$/i))
      return {
        quantity: match[1].to_i,
        name: match[2].strip,
        set_code: match[3].strip,
        collector_number: match[4].strip,
        foil: match[5].present?
      }
    end

    # Format 2: Quantity + name - 1 Lightning Bolt
    if (match = line.match(/^(\d+)\s+(.+)$/))
      return {
        quantity: match[1].to_i,
        name: match[2].strip,
        set_code: nil,
        collector_number: nil,
        foil: false
      }
    end

    # Format 3: Just a name - Lightning Bolt
    {
      quantity: 1,
      name: line.strip,
      set_code: nil,
      collector_number: nil,
      foil: false
    }
  end

  def find_bulk_card(parsed)
    if parsed[:set_code].present?
      BulkCard.find_by(
        "lower(name) = ? AND lower(set_code) = ? AND collector_number = ?",
        parsed[:name].downcase, parsed[:set_code].downcase, parsed[:collector_number]
      ) ||
      BulkCard.find_by(
        "lower(name) = ? AND lower(set_code) = ?",
        parsed[:name].downcase, parsed[:set_code].downcase
      ) ||
      BulkCard.where("lower(name) = ?", parsed[:name].downcase).first
    else
      BulkCard.where("lower(name) = ?", parsed[:name].downcase).first
    end
  end
end
