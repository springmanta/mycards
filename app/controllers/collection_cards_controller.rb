class CollectionCardsController < ApplicationController
  before_action :set_card, only: [:new, :edit], if: -> { params[:scryfall_id].present? }
  before_action :set_collection_card, only: [:show, :edit, :update, :destroy]

  def index
    @collections = Current.user.collections.includes(collection_cards: :card)
    @collection_cards = @collections.flat_map(&:collection_cards)
    @collection = @collections.first
    @view_mode = params[:view] || 'list'

    # Search by card name
    if params[:q].present?
      @collection_cards = @collection_cards.select { |cc| cc.card.name.downcase.include?(params[:q].downcase) }
    end

    # Filter by rarity
    if params[:rarity].present?
      @collection_cards = @collection_cards.select { |cc| cc.card.rarity == params[:rarity] }
    end

    # Filter by type
    if params[:type].present?
      @collection_cards = @collection_cards.select { |cc| cc.card.type_line&.include?(params[:type]) }
    end

    # Sorting
    @collection_cards = case params[:sort]
      when 'name_asc'
        @collection_cards.sort_by { |cc| cc.card.name }
      when 'name_desc'
        @collection_cards.sort_by { |cc| cc.card.name }.reverse
      when 'set_asc'
        @collection_cards.sort_by { |cc| cc.card.set_name || '' }
      when 'set_desc'
        @collection_cards.sort_by { |cc| cc.card.set_name || '' }.reverse
      when 'price_asc'
        @collection_cards.sort_by { |cc| cc.card.cardmarket_price || 0 }
      when 'price_desc'
        @collection_cards.sort_by { |cc| cc.card.cardmarket_price || 0 }.reverse
      else
        @collection_cards.sort_by(&:created_at).reverse # Most recent first by default
      end
  end

  def show
    @collection_card = CollectionCard.includes(:card, :collection).find(params[:id])
  end

  def new
    @collection_card = CollectionCard.new(quantity: 1, condition: "near_mint", foil: false)
    @collections = Current.user.collections

    card_name = @card_data["name"]
    response = CardSearch.conn.get("/cards/search", {
      q: "!\"#{card_name}\"",
      unique: "prints",
      order: "released"
    })

    if response.status == 200
      @all_printings = JSON.parse(response.body)["data"].reject { |p| p["digital"] }
    else
      @all_printings = [@card_data]
    end
  end

  def create
    # Handle BulkCard (new system)
    if params.dig(:collection_card, :bulk_card_id).present?
      create_from_bulk_card
    elsif params[:scryfall_id].present?
      # Handle old Scryfall system
      set_card
      create_from_scryfall
    else
      redirect_to root_path, alert: "Invalid card data"
    end
  end

  def edit
    @collections = Current.user.collections

    card_name = @collection_card.card.name
    response = CardSearch.conn.get("/cards/search", {
      q: "!\"#{card_name}\"",
      unique: "prints",
      order: "released"
    })

    if response.status == 200
      @all_printings = JSON.parse(response.body)["data"].reject { |p| p["digital"] }
    else
      @all_printings = []
    end
  end

  def update
    if @collection_card.update(collection_card_params)
      redirect_to collection_cards_path, notice: "#{@collection_card.card.name} updated successfully!"
    else
      @collections = Current.user.collections
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    card_name = @collection_card.card.name
    @collection_card.destroy
    redirect_to collection_cards_path, notice: "#{card_name} removed from collection."
  end

  private

  def create_from_bulk_card
    @bulk_card = BulkCard.find(params[:collection_card][:bulk_card_id])

    # Find or create a Card record from BulkCard
    @card = Card.find_or_initialize_by(scryfall_id: @bulk_card.scryfall_id)

    if @card.new_record?
      @card.assign_attributes(
        name: @bulk_card.name,
        set_name: @bulk_card.magic_set.name,
        set_code: @bulk_card.set_code,
        rarity: @bulk_card.rarity,
        mana_cost: @bulk_card.mana_cost,
        type_line: @bulk_card.type_line,
        oracle_text: @bulk_card.metadata['oracle_text'],
        flavor_text: @bulk_card.metadata['flavor_text'],
        image_url: @bulk_card.image_uri,
        power: @bulk_card.metadata['power'],
        toughness: @bulk_card.metadata['toughness'],
        cardmarket_price: @bulk_card.eur_price,
        back_image_url: @bulk_card.back_image_uri,
      )
      @card.save!
    end

    @card.cardmarket_price = @bulk_card.eur_price
    @card.prices_updated_at = Time.current
    @card.save!

    @collection_card = CollectionCard.new(collection_card_params.except(:bulk_card_id))
    @collection_card.card = @card
    @collection_card.collection ||= Current.user.ensure_collection

    if @collection_card.save
      redirect_to collection_path(@collection_card.collection), notice: "#{@card.name} added to #{@collection_card.collection.name}!"
    else
      @collections = Current.user.collections
      redirect_to card_path(@bulk_card), alert: "Could not add card to collection."
    end
  end

  def create_from_scryfall
    @card = Card.find_or_initialize_by(scryfall_id: @card_data["id"])

    if @card.new_record? || @card.image_url.nil?
      @card.assign_attributes(
        name: @card_data["name"],
        set_name: @card_data["set_name"],
        set_code: @card_data["set"],
        rarity: @card_data["rarity"],
        mana_cost: @card_data["mana_cost"],
        type_line: @card_data["type_line"],
        oracle_text: @card_data["oracle_text"],
        image_url: @card_data.dig("image_uris", "normal") ||
                  @card_data.dig("card_faces", 0, "image_uris", "normal"),
        power: @card_data["power"],
        toughness: @card_data["toughness"]
      )
    end

    @card.flavor_text = @card_data["flavor_text"]
    @card.artist = @card_data["artist"]

    if @card_data["prices"]
      @card.tcgplayer_price = @card_data.dig("prices", "usd")
      @card.cardmarket_price = @card_data.dig("prices", "eur")
      @card.prices_updated_at = Time.current
    end

    @card.save!

    @collection_card = CollectionCard.new(collection_card_params)
    @collection_card.card = @card
    @collection_card.collection ||= Current.user.ensure_collection

    if @collection_card.save
      redirect_to collection_path(@collection_card.collection), notice: "#{@card.name} added to #{@collection_card.collection.name}!"
    else
      @collections = Current.user.collections
      render :new, status: :unprocessable_entity
    end
  end

  def set_card
    scryfall_id = params[:scryfall_id]
    response = CardSearch.conn.get("/cards/#{scryfall_id}")
    @card_data = JSON.parse(response.body)
  end

  def set_collection_card
    @collection_card = CollectionCard.find(params[:id])
  end

  def collection_card_params
    params.require(:collection_card).permit(:collection_id, :quantity, :condition, :foil, :price_paid, :acquired_at, :bulk_card_id)
  end
end
