# lib/tasks/backfill.rake
namespace :backfill do
  desc "Backfill back face images from bulk data (memory efficient)"
  task back_faces: :environment do
    require "net/http"
    require "json"
    require "openssl"
    require "tempfile"

    puts "📥 Getting bulk data URL..."

    uri = URI("https://api.scryfall.com/bulk-data")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    response = http.request(Net::HTTP::Get.new(uri.request_uri))
    bulk_data = JSON.parse(response.body)

    default_cards = bulk_data["data"].find { |item| item["type"] == "default_cards" }
    download_uri = URI(default_cards["download_uri"])

    # Get only scryfall_ids that need back images
    dfc_ids = BulkCard.where("type_line LIKE ?", "%//%")
                      .where(back_image_uri: nil)
                      .pluck(:scryfall_id)
                      .to_set

    missing_front_ids = BulkCard.where(image_uri: nil)
                                .pluck(:scryfall_id)
                                .to_set

    target_ids = dfc_ids | missing_front_ids

    if target_ids.empty?
      puts "✅ Nothing to backfill!"
      return
    end

    puts "Found #{target_ids.size} cards to check."
    puts "📥 Downloading to temp file..."

    # Stream to temp file instead of loading into memory
    tmpfile = Tempfile.new(['scryfall', '.json'], encoding: 'ascii-8bit')
    http2 = Net::HTTP.new(download_uri.host, download_uri.port)
    http2.use_ssl = true
    http2.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http2.read_timeout = 600

    http2.request(Net::HTTP::Get.new(download_uri.request_uri)) do |response|
      response.read_body do |chunk|
        tmpfile.write(chunk)
      end
    end
    tmpfile.close

    puts "Processing file..."

    updated = 0
    front_fixed = 0
    buffer = ""
    in_object = false
    depth = 0

    # Parse JSON objects one at a time instead of loading entire array
    File.open(tmpfile.path, 'r:UTF-8') do |file|
      file.each_char do |char|
        if char == '{'
          in_object = true if depth == 0
          depth += 1
        end

        buffer << char if in_object

        if char == '}'
          depth -= 1
          if depth == 0 && in_object
            in_object = false

            begin
              card = JSON.parse(buffer)

              if target_ids.include?(card["id"])
                faces = card["card_faces"]
                if faces&.length&.>= 2
                  back_image = faces[1].dig("image_uris", "normal")
                  front_image = faces[0].dig("image_uris", "normal")

                  bulk_card = BulkCard.find_by(scryfall_id: card["id"])
                  if bulk_card
                    updates = {}
                    updates[:back_image_uri] = back_image if back_image && bulk_card.back_image_uri.nil?
                    if bulk_card.image_uri.nil? && front_image
                      updates[:image_uri] = front_image
                      front_fixed += 1
                    end

                    if updates.any?
                      bulk_card.update_columns(updates)
                      updated += 1
                    end
                  end
                end
              end
            rescue JSON::ParserError
              # skip malformed objects
            end

            buffer = ""
            print "\rUpdated: #{updated} | Front fixed: #{front_fixed}"
          end
        end
      end
    end

    tmpfile.unlink
    GC.start

    puts "\n✅ Done! Updated #{updated} double-faced cards, fixed #{front_fixed} missing front images."
  end
end
