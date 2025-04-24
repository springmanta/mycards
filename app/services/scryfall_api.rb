require "net/http"
require "uri"
require "json"
require "cgi"

class ScryfallApi
  BASE_URL = "https://api.scryfall.com"
  RATE_LIMIT_DELAY = 0.1 # Delay in seconds (100 milliseconds)

  def initialize
    @headers = {
      "User-Agent" => "MyCardsApp/1.0 (springmanta personal use)",
      "Accept" => "application/json"
    }
  end

  # Fetch card details by name
  def search_cards(query)
    return [] if query.blank?

    encoded_query = CGI.escape(query)
    uri = URI("#{BASE_URL}/cards/search?q=#{encoded_query}")
    response = make_request(uri)

    if response.is_a?(Net::HTTPSuccess)
      json = JSON.parse(response.body)
      return json["data"] || []
    else
      Rails.logger.error("Scryfall Search Error: #{response.code} - #{response.body}")
      return []
    end
  rescue => e
    Rails.logger.error("Scryfall API Error: #{e.message}")
    return []
  end

  # Fetch card details by ID
  def get_card_by_id(scryfall_id)
    uri = URI("#{BASE_URL}/cards/#{scryfall_id}")
    response = make_request(uri)

    return JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)

    Rails.logger.error("Scryfall Get Error: #{response.body}")
    nil
  end

  # Fetch all prints (versions) of a card by name
  def get_card_prints(card_name)
    return [] if card_name.blank?

    encoded_name = CGI.escape("!\"#{card_name}\"")
    uri = URI("#{BASE_URL}/cards/search?q=#{encoded_name}&unique=prints")
    response = make_request(uri)

    if response.is_a?(Net::HTTPSuccess)
      json = JSON.parse(response.body)
      return json["data"] || []
    else
      Rails.logger.error("Scryfall Prints Error: #{response.code} - #{response.body}")
      return []
    end
  rescue => e
    Rails.logger.error("Scryfall API Error: #{e.message}")
    return []
  end

  private

  # Make HTTP request to Scryfall API
  def make_request(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri, @headers)
    http.request(request)
  end
end
