require "faraday"

class CardSearch
  BASE_URL = "https://api.scryfall.com"
  MIN_DELAY = 0.1

  def self.conn
    @conn ||= Faraday.new(url: BASE_URL) do |faraday|
      faraday.headers["Accept"] = "application/json"
      faraday.headers["User-Agent"] = "myCardsApp (https://mycards-db.com)"
      faraday.adapter Faraday.default_adapter
    end
  end

  def self.call(name)
    response = conn.get("/cards/named", { fuzzy: name })

    case response.status
    when 200
      JSON.parse(response.body)
    when 404
      { error: "Card not found" }
    else
      Rails.logger.error("Scryfall API error: #{response.status} - #{response.body}")
      { error: "Something went wrong" }
    end
  rescue Faraday::ConnectionFailed => e
    Rails.logger.error("Connection failed: #{e.message}")
    { error: "Connection failed" }
  end
end
