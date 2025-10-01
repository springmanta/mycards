class CardsController < ApplicationController
  allow_unauthenticated_access only: [:search]

  def index
    @cards = Current.user.cards
  end
  
  def search
    @query = params[:q]
    @cards = []
    @card_name = nil

    if @query.present?
      result = CardSearch.search_printings(@query)

      Rails.logger.info "Search result: #{result.inspect}"

      @cards = result.is_a?(Array) ? result : []
      @card_name = @cards.first&.dig("name") if @cards.any?
    end
  end
end
