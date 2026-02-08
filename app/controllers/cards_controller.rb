class CardsController < ApplicationController
  allow_unauthenticated_access only: [:show, :autocomplete, :search]

  def index
    @cards = Current.user.cards
  end

  def show
    @card = BulkCard.find(params[:id])
    @collections = current_user&.collections || []
    @all_printings = BulkCard.where(name: @card.name)
                            .includes(:magic_set)
                            .order(:set_code)
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

    search_name = @query.split(" // ").first.strip

    @cards = BulkCard.where("bulk_cards.name ILIKE ?", "%#{search_name}%")
                    .includes(:magic_set)

    # Filter by rarity
    if params[:rarity].present?
      @cards = @cards.where(rarity: params[:rarity])
    end

    # Filter by type
    if params[:type].present?
      @cards = @cards.where("bulk_cards.type_line ILIKE ?", "%#{params[:type]}%")
    end

    # Sorting
    @cards = case params[:sort]
    when "name_asc" then @cards.order("bulk_cards.name ASC")
    when "name_desc" then @cards.order("bulk_cards.name DESC")
    when "set_asc" then @cards.order("magic_sets.name ASC")
    when "set_desc" then @cards.order("magic_sets.name DESC")
    when "price_asc" then @cards.order("bulk_cards.eur_price ASC NULLS LAST")
    when "price_desc" then @cards.order("bulk_cards.eur_price DESC NULLS LAST")
    else @cards.order("magic_sets.name", :collector_number)
    end

    @card_name = @cards.first&.name if @cards.any?
  end
end
