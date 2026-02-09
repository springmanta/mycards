class CardsController < ApplicationController
  allow_unauthenticated_access only: [ :show, :autocomplete, :search, :match ]

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

    cards = BulkCard
      .where("LOWER(name) LIKE ?", "#{query.downcase}%")
      .distinct
      .order(:name)
      .limit(10)
      .pluck(:name)

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

  def match
    query = params[:name]&.strip

    if query.blank? || query.length < 3
      render json: { matches: [] }
      return
    end

  # Clean up OCR artifacts
  clean_name = query.gsub(/[^a-zA-Z\s',\-]/, '').strip

  cards = BulkCard
    .where("lower(name) LIKE ?", "#{clean_name.downcase}%")
    .includes(:magic_set)
    .select("DISTINCT ON (name) *")
    .order(:name)
    .limit(5)

  # Fallback to contains if no prefix match
  if cards.empty?
    cards = BulkCard
      .where("lower(name) LIKE ?", "%#{clean_name.downcase}%")
      .includes(:magic_set)
      .select("DISTINCT ON (name) *")
      .order(:name)
      .limit(5)
  end

  render json: {
    matches: cards.map { |c|
      {
        id: c.id,
        name: c.name,
        set_name: c.magic_set&.name,
        set_code: c.set_code,
        rarity: c.rarity,
        image_uri: c.image_uri,
        url: card_path(c)
      }
    }
  }
  end
end
