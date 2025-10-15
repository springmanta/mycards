# Rake task to import sets

namespace :scryfall do
  desc "Import set data from Scryfall"
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
end

# Rake task to import bulk cards

namespace :scryfall do
  desc "Import bulk card data from Scryfall"
  task import_bulk_cards: :environment do
    require "net/http"
    require "json"
    require "zlib"
    require "openssl"

    puts "Fetching bulk data info from Scryfall..."

    # Get the bulk data download URL
    uri = URI("https://api.scryfall.com/bulk-data")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    bulk_data = JSON.parse(response.body)

    # Find the "Default Cards" bulk data (paper cards only)
    default_cards = bulk_data["data"].find { |item| item["type"] == "default_cards" }
    download_uri = URI(default_cards["download_uri"])

    puts "Downloading bulk data (~150MB, this will take a few minutes)..."
    puts "URL: #{download_uri}"

    # Download the bulk data with SSL bypass
    http2 = Net::HTTP.new(download_uri.host, download_uri.port)
    http2.use_ssl = true
    http2.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http2.read_timeout = 300  # 5 minutes timeout for large download

    request2 = Net::HTTP::Get.new(download_uri.request_uri)
    json_data = http2.request(request2).body
    cards = JSON.parse(json_data)

    puts "Processing #{cards.size} cards..."

    imported = 0
    skipped = 0
    batch_size = 1000

    cards.each_slice(batch_size) do |batch|
      records = batch.map do |card|
        # Skip digital-only cards
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
          metadata: card.slice("oracle_text", "power", "toughness", "loyalty", "colors", "color_identity"),
          created_at: Time.current,
          updated_at: Time.current
        }
      end.compact

      # Bulk insert
      BulkCard.insert_all(records, unique_by: :scryfall_id) if records.any?

      imported += records.size
      skipped += batch.size - records.size

      print "\rImported: #{imported} | Skipped: #{skipped}"
    end

    puts "\n✅ Import complete!"
    puts "Total cards in database: #{BulkCard.count}"
  end
end
