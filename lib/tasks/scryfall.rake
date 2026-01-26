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

   desc "Smart update - only fetch cards from new or incomplete sets"
  task smart_update: :environment do
    require "net/http"
    require "json"
    require "openssl"

    puts "🔄 Smart update - checking for incomplete sets..."

    # Get all sets from Scryfall
    uri = URI("https://api.scryfall.com/sets")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    response = http.request(Net::HTTP::Get.new(uri.request_uri))
    scryfall_sets = JSON.parse(response.body)["data"]

    # Find new sets
    existing_codes = MagicSet.pluck(:code).to_set
    new_sets = scryfall_sets.reject { |s| s["digital"] || existing_codes.include?(s["code"]) }

    new_sets.each do |set|
      MagicSet.create!(
        code: set["code"],
        name: set["name"],
        icon_svg_uri: set["icon_svg_uri"],
        released_at: set["released_at"]
      )
    end

    puts "✅ Added #{new_sets.size} new sets"

    # Find incomplete sets (released in last 90 days or missing cards)
    recent_date = 90.days.ago
    incomplete_sets = []

    MagicSet.where("released_at > ?", recent_date).or(MagicSet.where(released_at: nil)).each do |local_set|
      scryfall_set = scryfall_sets.find { |s| s["code"] == local_set.code }
      next unless scryfall_set

      expected = scryfall_set["card_count"]
      actual = local_set.bulk_cards.count

      if actual < expected
        incomplete_sets << {
          set: local_set,
          code: local_set.code,
          expected: expected,
          actual: actual
        }
      end
    end

    if incomplete_sets.empty?
      puts "✅ All recent sets are complete!"
      return
    end

    puts "\nFound #{incomplete_sets.size} incomplete sets:"
    incomplete_sets.each do |info|
      puts "  #{info[:set].name} (#{info[:code]}): #{info[:actual]}/#{info[:expected]} cards"
    end

    # Fetch cards for each incomplete set using Scryfall API
    total_added = 0
    incomplete_sets.each do |info|
      puts "\n📥 Fetching cards for #{info[:set].name}..."

      set_code = info[:code]
      page = 1
      has_more = true
      added = 0

      while has_more
        search_uri = URI("https://api.scryfall.com/cards/search?q=set:#{set_code}+game:paper+-is:digital&page=#{page}")

        sleep(0.1) # Respect Scryfall's rate limit

        search_response = http.request(Net::HTTP::Get.new(search_uri.request_uri))

        if search_response.code != "200"
          puts "  ⚠️  Error fetching page #{page}: #{search_response.code}"
          break
        end

        search_data = JSON.parse(search_response.body)
        cards = search_data["data"]

        # Process cards in batch
        new_records = []
        cards.each do |card|
          next if BulkCard.exists?(scryfall_id: card["id"])

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
        end

        if new_records.any?
          BulkCard.insert_all(new_records, unique_by: :scryfall_id)
          added += new_records.size
          total_added += new_records.size
        end

        print "\r  Added #{added} cards..."

        has_more = search_data["has_more"]
        page += 1
      end

      puts " ✅"
    end

    puts "\n✅ Smart update complete!"
    puts "Total new cards added: #{total_added}"
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
