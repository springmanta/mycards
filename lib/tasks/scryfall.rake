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

  desc "Update cards and prices - only add new cards and update existing prices"
  task update_cards_and_prices: :environment do
    require "net/http"
    require "json"
    require "openssl"

    puts "🔄 Updating cards and prices..."

    # First update sets
    Rake::Task["scryfall:update_sets"].invoke

    # Then update cards
    uri = URI("https://api.scryfall.com/bulk-data")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    response = http.request(Net::HTTP::Get.new(uri.request_uri))
    bulk_data = JSON.parse(response.body)

    default_cards = bulk_data["data"].find { |item| item["type"] == "default_cards" }
    download_uri = URI(default_cards["download_uri"])

    puts "📥 Downloading bulk data..."

    http2 = Net::HTTP.new(download_uri.host, download_uri.port)
    http2.use_ssl = true
    http2.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http2.read_timeout = 300

    json_data = http2.request(Net::HTTP::Get.new(download_uri.request_uri)).body
    cards = JSON.parse(json_data)

    puts "Processing #{cards.size} cards..."

    existing_ids = BulkCard.pluck(:scryfall_id).to_set
    new_cards = 0
    updated_prices = 0

    cards.each_slice(1000) do |batch|
      new_records = []

      batch.each do |card|
        next if card["digital"] == true
        next unless card["games"]&.include?("paper")

        if existing_ids.include?(card["id"])
          # Update price for existing card
          bulk_card = BulkCard.find_by(scryfall_id: card["id"])
          new_price = card.dig("prices", "eur")&.to_f

          if bulk_card && new_price && bulk_card.eur_price != new_price
            bulk_card.update(eur_price: new_price)
            updated_prices += 1
          end
        else
          # Add new card
          new_records << {
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
      end

      BulkCard.insert_all(new_records, unique_by: :scryfall_id) if new_records.any?

      print "\rNew cards: #{new_cards} | Updated prices: #{updated_prices}"
    end

    puts "\n✅ Update complete!"
    puts "New cards added: #{new_cards}"
    puts "Prices updated: #{updated_prices}"
    puts "Total cards: #{BulkCard.count}"
  end

  desc "Complete incomplete sets - add missing cards from partially imported sets"
  task complete_incomplete_sets: :environment do
    require "net/http"
    require "json"
    require "openssl"

    puts "🔍 Checking for incomplete sets..."

    # Get all sets and their expected card counts from Scryfall
    uri = URI("https://api.scryfall.com/sets")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    response = http.request(Net::HTTP::Get.new(uri.request_uri))
    sets_data = JSON.parse(response.body)

    incomplete_sets = []

    sets_data["data"].each do |set|
      next if set["digital"] != false

      local_set = MagicSet.find_by(code: set["code"])
      next unless local_set

      expected_count = set["card_count"]
      actual_count = local_set.bulk_cards.count

      if actual_count < expected_count
        incomplete_sets << {
          code: set["code"],
          name: set["name"],
          expected: expected_count,
          actual: actual_count,
          missing: expected_count - actual_count
        }
      end
    end

    if incomplete_sets.empty?
      puts "✅ All sets are complete!"
      return
    end

    puts "Found #{incomplete_sets.size} incomplete sets:"
    incomplete_sets.each do |set|
      puts "  - #{set[:name]} (#{set[:code]}): #{set[:actual]}/#{set[:expected]} cards (missing #{set[:missing]})"
    end

    puts "\n📥 Downloading bulk data to complete sets..."

    # Download bulk data
    uri = URI("https://api.scryfall.com/bulk-data")
    response = http.request(Net::HTTP::Get.new(uri.request_uri))
    bulk_data = JSON.parse(response.body)

    default_cards = bulk_data["data"].find { |item| item["type"] == "default_cards" }
    download_uri = URI(default_cards["download_uri"])

    http2 = Net::HTTP.new(download_uri.host, download_uri.port)
    http2.use_ssl = true
    http2.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http2.read_timeout = 300

    json_data = http2.request(Net::HTTP::Get.new(download_uri.request_uri)).body
    cards = JSON.parse(json_data)

    puts "Processing cards for incomplete sets..."

    incomplete_codes = incomplete_sets.map { |s| s[:code] }.to_set
    existing_ids = BulkCard.pluck(:scryfall_id).to_set
    added_cards = 0

    cards.each_slice(1000) do |batch|
      new_records = []

      batch.each do |card|
        # Only process cards from incomplete sets
        next unless incomplete_codes.include?(card["set"])
        next if existing_ids.include?(card["id"])
        next if card["digital"] == true
        next unless card["games"]&.include?("paper")

        new_records << {
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
        added_cards += 1
      end

      BulkCard.insert_all(new_records, unique_by: :scryfall_id) if new_records.any?
      print "\rAdded: #{added_cards} cards"
    end

    puts "\n✅ Completed incomplete sets!"
    puts "Total cards added: #{added_cards}"
  end

  desc "Update cards, prices, and complete incomplete sets"
  task weekly_update: :environment do
    Rake::Task["scryfall:update_cards_and_prices"].invoke
    Rake::Task["scryfall:complete_incomplete_sets"].invoke
  end
end
