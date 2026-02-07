# lib/tasks/backfill.rake
namespace :backfill do
  desc "Backfill back face images from bulk data download"
  task back_faces: :environment do
    require "net/http"
    require "json"
    require "openssl"

    puts "📥 Downloading bulk data..."

    uri = URI("https://api.scryfall.com/bulk-data")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    response = http.request(Net::HTTP::Get.new(uri.request_uri))
    bulk_data = JSON.parse(response.body)

    default_cards = bulk_data["data"].find { |item| item["type"] == "default_cards" }
    download_uri = URI(default_cards["download_uri"])

    http2 = Net::HTTP.new(download_uri.host, download_uri.port)
    http2.use_ssl = true
    http2.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http2.read_timeout = 300

    puts "Downloading (~150MB)..."
    json_data = http2.request(Net::HTTP::Get.new(download_uri.request_uri)).body
    cards = JSON.parse(json_data)

    puts "Processing #{cards.size} cards for back faces..."

    updated = 0
    front_fixed = 0

    cards.each_slice(1000) do |batch|
      batch.each do |card|
        faces = card["card_faces"]
        next unless faces&.length&.>= 2

        back_image = faces[1].dig("image_uris", "normal")
        front_image = faces[0].dig("image_uris", "normal")
        next unless back_image

        bulk_card = BulkCard.find_by(scryfall_id: card["id"])
        next unless bulk_card

        updates = { back_image_uri: back_image }

        if bulk_card.image_uri.nil? && front_image
          updates[:image_uri] = front_image
          front_fixed += 1
        end

        bulk_card.update_columns(updates)
        updated += 1
      end

      print "\rUpdated: #{updated} | Front fixed: #{front_fixed}"
    end

    puts "\n✅ Done! Updated #{updated} double-faced cards, fixed #{front_fixed} missing front images."
  end
end
