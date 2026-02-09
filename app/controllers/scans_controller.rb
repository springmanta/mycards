class ScansController < ApplicationController
  def new
  end

  def create
    unless params[:image].present?
      redirect_to new_scan_path, alert: "Please take a photo of a card"
      return
    end

    # Call Vision API via REST (no heavy gem needed)
    require "net/http"
    require "json"
    require "base64"

    image_data = Base64.strict_encode64(params[:image].read)

    credentials = Rails.application.credentials.dig(:google_cloud, :credentials)
    token = fetch_access_token(credentials)

    uri = URI("https://vision.googleapis.com/v1/images:annotate")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{token}"
    request["Content-Type"] = "application/json"
    request.body = {
      requests: [{
        image: { content: image_data },
        features: [{ type: "TEXT_DETECTION", maxResults: 1 }]
      }]
    }.to_json

    response = http.request(request)
    result = JSON.parse(response.body)

    texts = result.dig("responses", 0, "textAnnotations")

    if texts.blank?
      redirect_to new_scan_path, alert: "Couldn't read text from the image. Try again with better lighting."
      return
    end

    full_text = texts.first["description"]
    Rails.logger.info "Vision API detected: #{full_text}"

    # Extract card name - first line is usually the name
    lines = full_text.split("\n").map(&:strip).reject(&:blank?)
    card_name = lines.first

    # Clean OCR artifacts (mana symbols, etc)
    card_name = card_name.gsub(/[{}]/, '').gsub(/\d+$/, '').strip

    Rails.logger.info "Extracted card name: #{card_name}"

    @matches = BulkCard.where("bulk_cards.name ILIKE ?", "%#{card_name}%")
                      .includes(:magic_set)
                      .select("DISTINCT ON (bulk_cards.name) bulk_cards.*")
                      .order("bulk_cards.name")
                      .limit(10)

    if @matches.empty? && card_name.split.length > 2
      shorter_name = card_name.split[0..1].join(" ")
      @matches = BulkCard.where("bulk_cards.name ILIKE ?", "%#{shorter_name}%")
                        .includes(:magic_set)
                        .select("DISTINCT ON (bulk_cards.name) bulk_cards.*")
                        .order("bulk_cards.name")
                        .limit(10)
    end

    @detected_text = card_name
    @all_text = full_text

    if @matches.length == 1
      redirect_to card_path(@matches.first), notice: "Found: #{@matches.first.name}"
    else
      render :create
    end
  end

  private

  def fetch_access_token(credentials)
    require "openssl"
    require "json"

    now = Time.now.to_i
    payload = {
      iss: credentials["client_email"],
      scope: "https://www.googleapis.com/auth/cloud-vision",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600
    }

    # Build JWT
    header = Base64.urlsafe_encode64({ alg: "RS256", typ: "JWT" }.to_json).tr("=", "")
    claims = Base64.urlsafe_encode64(payload.to_json).tr("=", "")
    signing_input = "#{header}.#{claims}"

    key = OpenSSL::PKey::RSA.new(credentials["private_key"])
    signature = Base64.urlsafe_encode64(key.sign("SHA256", signing_input)).tr("=", "")
    jwt = "#{signing_input}.#{signature}"

    # Exchange JWT for access token
    uri = URI("https://oauth2.googleapis.com/token")
    response = Net::HTTP.post_form(uri, {
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt
    })

    JSON.parse(response.body)["access_token"]
  end
end
