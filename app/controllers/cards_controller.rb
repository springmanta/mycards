class CardsController < ApplicationController
  allow_unauthenticated_access only: [:show, :autocomplete, :search]

  def index
    @cards = Current.user.cards
  end

  def show
    @card = BulkCard.find(params[:id])
    @collections = current_user&.collections || []
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

    if @query.blank?
      redirect_back fallback_location: root_path, alert: "Please enter a card name to search"
      return
    end

    # Search for cards - handle double-faced cards by searching just the front face
    search_name = @query.split(" // ").first.strip

    # Search local BulkCard database - specify bulk_cards.name explicitly
    @cards = BulkCard.where("bulk_cards.name ILIKE ?", "%#{search_name}%")
                    .includes(:magic_set)
                    .order('magic_sets.name', :collector_number)

    @card_name = @cards.first&.name if @cards.any?

    Rails.logger.info "Found #{@cards.length} printings for '#{search_name}'"
  end
end
