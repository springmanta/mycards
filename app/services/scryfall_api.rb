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
  def search_cards(name)
    return nil if name.blank? # Prevent error if name is nil or empty

    # Using CGI.escape to properly encode the card name
    encoded_name = CGI.escape(name)

    uri = URI("#{BASE_URL}/cards/named?fuzzy=#{encoded_name}")
    response = make_request(uri)

    return JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)

    Rails.logger.error("Scryfall Error: #{response.body}")
    nil
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
