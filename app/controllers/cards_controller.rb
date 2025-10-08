class CardsController < ApplicationController
  allow_unauthenticated_access only: [:search, :autocomplete]

  def index
    @cards = Current.user.cards
  end

  def autocomplete
    query = params[:q]

    if query.blank? || query.length < 2
      render json: { data: [] }
      return
    end

    # Search local database instead of Scryfall API
    cards = BulkCard.search_by_name(query).pluck(:name).uniq

    render json: { data: cards }
  end

  def search
    @query = params[:q]
    @cards = []
    @card_name = nil

    if @query.blank?
      redirect_back fallback_location: root_path, alert: "Please enter a card name to search"
      return
    end

    @cards = []
    @card_name = nil

    result = CardSearch.search_printings(@query)
    Rails.logger.info "Search result: #{result.inspect}"
    @cards = result.is_a?(Array) ? result : []
    @card_name = @cards.first&.dig("name") if @cards.any?
  end
end
