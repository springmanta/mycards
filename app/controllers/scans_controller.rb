class ScansController < ApplicationController
  def new
  end

  def create
    unless params[:image].present?
      redirect_to new_scan_path, alert: "Please take a photo of a card"
      return
    end

    client = Google::Cloud::Vision.image_annotator do |config|
      config.credentials = Rails.application.credentials.dig(:google_cloud, :credentials)
    end

    image_content = params[:image].read

    request = {
      requests: [{
        image: { content: image_content },
        features: [{ type: :TEXT_DETECTION }]
      }]
    }

    response = client.batch_annotate_images(request)
    texts = response.responses.first&.text_annotations

    if texts.blank?
      redirect_to new_scan_path, alert: "Couldn't read text from the image. Try again with better lighting."
      return
    end

    full_text = texts.first.description
    Rails.logger.info "Vision API detected: #{full_text}"

    lines = full_text.split("\n").map(&:strip).reject(&:blank?)
    card_name = lines.first

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
end
