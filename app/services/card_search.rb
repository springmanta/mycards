require "faraday"

class CardSearch
  BASE_URL = "https://api.scryfall.com"
  MIN_DELAY = 0.1

  def self.conn
    @conn ||= Faraday.new(url: BASE_URL) do |faraday|
      faraday.headers["Accept"] = "application/json"
      faraday.headers["User-Agent"] = "myCardsApp/1.0 (https://mycards-db.com)"
      faraday.adapter Faraday.default_adapter
    end
  end

  def self.rate_limit
    @last_request ||= Time.now - MIN_DELAY
    elapsed = Time.now - @last_request
    sleep(MIN_DELAY - elapsed) if elapsed < MIN_DELAY
    @last_request = Time.now
  end

  def self.search_printings(name)
    if name.length < 8
      rate_limit
      response = conn.get("/cards/search", {
        q: "name:/^#{name}/",
        unique: "cards"
      })
      return response.status == 200 ? JSON.parse(response.body)["data"] : []
    end

  # For longer queries, try fuzzy match first
  rate_limit
  fuzzy_response = conn.get("/cards/named", { fuzzy: name })

  if fuzzy_response.status == 200
    exact_name = JSON.parse(fuzzy_response.body)["name"]

    rate_limit
    response = conn.get("/cards/search", {
      q: "!\"#{exact_name}\"",
      unique: "prints",
      order: "released"
    })

    return JSON.parse(response.body)["data"] if response.status == 200
  end

  # Fallback: partial name search
  rate_limit
  response = conn.get("/cards/search", {
    q: "name:/^#{name}/",
    unique: "cards"
  })

  response.status == 200 ? JSON.parse(response.body)["data"] : []
rescue Faraday::ConnectionFailed => e
  Rails.logger.error("Connection failed: #{e.message}")
  []
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
