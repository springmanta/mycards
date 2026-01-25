# lib/tasks/scryfall.rake

namespace :scryfall do
  desc "Import set data from Scryfall (full import)"
  task import_sets: :environment do
    require "net/http"
    require "json"
    require "openssl"

    puts "Fetching sets from Scryfall..."

    uri = URI("https://api.scryfall.com/sets")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    sets_data = JSON.parse(response.body)

    MagicSet.delete_all

    imported = 0
    skipped = 0

    sets_data["data"].each do |set|
      unless set["digital"] == false
        skipped += 1
        next
      end

      MagicSet.create!(
        code: set["code"],
        name: set["name"],
        icon_svg_uri: set["icon_svg_uri"],
        released_at: set["released_at"]
      )

      imported += 1
    end

    puts "✅ Imported #{MagicSet.count} sets"
  end

  desc "Update sets - add new sets only, don't delete existing"
  task update_sets: :environment do
    require "net/http"
    require "json"
    require "openssl"

    puts "🔄 Checking for new sets..."

    uri = URI("https://api.scryfall.com/sets")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    sets_data = JSON.parse(response.body)

    existing_codes = MagicSet.pluck(:code).to_set
    new_sets = 0

    sets_data["data"].each do |set|
      next if set["digital"] != false
      next if existing_codes.include?(set["code"])

      MagicSet.create!(
        code: set["code"],
        name: set["name"],
        icon_svg_uri: set["icon_svg_uri"],
        released_at: set["released_at"]
      )

      new_sets += 1
    end

    puts "✅ Added #{new_sets} new sets (Total: #{MagicSet.count})"
  end

  desc "Import bulk card data from Scryfall (full import)"
  task import_bulk_cards: :environment do
    require "net/http"
    require "json"
    require "zlib"
    require "openssl"

    puts "Fetching bulk data info from Scryfall..."

    uri = URI("https://api.scryfall.com/bulk-data")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    bulk_data = JSON.parse(response.body)

    default_cards = bulk_data["data"].find { |item| item["type"] == "default_cards" }
    download_uri = URI(default_cards["download_uri"])

    puts "Downloading bulk data (~150MB, this will take a few minutes)..."
    puts "URL: #{download_uri}"

    http2 = Net::HTTP.new(download_uri.host, download_uri.port)
    http2.use_ssl = true
    http2.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http2.read_timeout = 300

    request2 = Net::HTTP::Get.new(download_uri.request_uri)
    json_data = http2.request(request2).body
    cards = JSON.parse(json_data)

    puts "Processing #{cards.size} cards..."

    puts "Deleting existing cards..."
    BulkCard.delete_all

    imported = 0
    skipped = 0
    batch_size = 1000

    cards.each_slice(batch_size) do |batch|
      records = batch.map do |card|
        next if card["digital"] == true
        next unless card["games"]&.include?("paper")

        {
          scryfall_id: card["id"],
          name: card["name"],
          set_code: card["set"],
          collector_number: card["collector_number"],
          eur_price: card.dig("prices", "eur")&.to_f,
          image_uri: card.dig("image_uris", "normal") || card.dig("card_faces", 0, "image_uris", "normal"),
          rarity: card["rarity"],
          type_line: card["type_line"],
          mana_cost: card["mana_cost"],
          metadata: card.slice("oracle_text", "power", "toughness", "loyalty", "colors", "color_identity", "flavor_text", "artist"),
          created_at: Time.current,
          updated_at: Time.current
        }
      end.compact

      BulkCard.insert_all(records, unique_by: :scryfall_id) if records.any?

      imported += records.size
      skipped += batch.size - records.size

      print "\rImported: #{imported} | Skipped: #{skipped}"
    end

    puts "\n✅ Import complete!"
    puts "Total cards in database: #{BulkCard.count}"
  end

  desc "Memory-efficient update: cards and prices"
  task efficient_update: :environment do
    require "net/http"
    require "json"
    require "openssl"

    puts "🔄 Starting memory-efficient update..."

    # First update sets
    puts "Updating sets..."
    uri = URI("https://api.scryfall.com/sets")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    response = http.request(Net::HTTP::Get.new(uri.request_uri))
    sets_data = JSON.parse(response.body)

    existing_codes = MagicSet.pluck(:code).to_set
    new_sets = 0

    sets_data["data"].each do |set|
      next if set["digital"] != false
      next if existing_codes.include?(set["code"])

      MagicSet.create!(
        code: set["code"],
        name: set["name"],
        icon_svg_uri: set["icon_svg_uri"],
        released_at: set["released_at"]
      )
      new_sets += 1
    end

    puts "✅ Added #{new_sets} new sets"

    # Get bulk data URL
    puts "Getting bulk data URL..."
    uri = URI("https://api.scryfall.com/bulk-data")
    response = http.request(Net::HTTP::Get.new(uri.request_uri))
    bulk_data = JSON.parse(response.body)

    default_cards = bulk_data["data"].find { |item| item["type"] == "default_cards" }
    download_uri = URI(default_cards["download_uri"])

    puts "📥 Streaming bulk data (memory efficient)..."

    # Stream and process in small batches
    http2 = Net::HTTP.new(download_uri.host, download_uri.port)
    http2.use_ssl = true
    http2.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http2.read_timeout = 600

    # Get existing IDs in batches to avoid loading all at once
    puts "Loading existing card IDs..."
    existing_ids = Set.new
    BulkCard.find_in_batches(batch_size: 5000) do |batch|
      existing_ids.merge(batch.map(&:scryfall_id))
      GC.start # Force garbage collection
    end

    new_cards = 0
    updated_prices = 0
    batch_records = []
    batch_size = 500

    request2 = Net::HTTP::Get.new(download_uri.request_uri)
    json_data = http2.request(request2).body

    # Parse JSON line by line if possible, or in chunks
    cards = JSON.parse(json_data)
    total = cards.size

    cards.each_with_index do |card, index|
      next if card["digital"] == true
      next unless card["games"]&.include?("paper")

      if existing_ids.include?(card["id"])
        # Update price for existing card
        bulk_card = BulkCard.find_by(scryfall_id: card["id"])
        new_price = card.dig("prices", "eur")&.to_f

        if bulk_card && new_price && bulk_card.eur_price != new_price
          bulk_card.update_column(:eur_price, new_price)
          updated_prices += 1
        end
      else
        # Prepare new card for batch insert
        batch_records << {
          scryfall_id: card["id"],
          name: card["name"],
          set_code: card["set"],
          collector_number: card["collector_number"],
          eur_price: card.dig("prices", "eur")&.to_f,
          image_uri: card.dig("image_uris", "normal") || card.dig("card_faces", 0, "image_uris", "normal"),
          rarity: card["rarity"],
          type_line: card["type_line"],
          mana_cost: card["mana_cost"],
          metadata: card.slice("oracle_text", "power", "toughness", "loyalty", "colors", "color_identity", "flavor_text", "artist"),
          created_at: Time.current,
          updated_at: Time.current
        }
        new_cards += 1
      end

      # Insert batch and clear memory
      if batch_records.size >= batch_size
        BulkCard.insert_all(batch_records, unique_by: :scryfall_id)
        batch_records.clear
        GC.start
        print "\rProcessed: #{index + 1}/#{total} | New: #{new_cards} | Updated: #{updated_prices}"
      end
    end

    # Insert remaining records
    BulkCard.insert_all(batch_records, unique_by: :scryfall_id) if batch_records.any?

    puts "\n✅ Update complete!"
    puts "New cards: #{new_cards}"
    puts "Updated prices: #{updated_prices}"
  end
end
