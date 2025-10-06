class CollectionCardsController < ApplicationController
  before_action :set_card, only: [:new, :create]
  before_action :set_collection_card, only: [:edit, :update, :destroy]

  def index
    @collections = Current.user.collections.includes(collection_cards: :card)
    @collection_cards = @collections.flat_map(&:collection_cards).sort_by(&:created_at).reverse
    @collection = @collections.first
    @view_mode = params[:view] || 'list'
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
      @all_printings = JSON.parse(response.body)["data"]
    else
      @all_printings = [@card_data]
  end
end

  def create
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

    # Always update these fields
    @card.flavor_text = @card_data["flavor_text"]
    @card.artist = @card_data["artist"]

    # Add pricing data
    if @card_data["prices"]
      @card.tcgplayer_price = @card_data.dig("prices", "usd")
      @card.cardmarket_price = @card_data.dig("prices", "eur")
      @card.prices_updated_at = Time.current
    end

    @card.save!

    @collection_card = CollectionCard.new(collection_card_params)
    @collection_card.card = @card

    if @collection_card.save
      redirect_to collection_cards_path, notice: "#{@card.name} added to your collection."
    else
      @collections = Current.user.collections
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @collections = Current.user.collections
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
    card_name = params[:scryfall_id]
    @collection_card.destroy
    redirect_to collection_cards_path, notice: "#{card_name} removed from collection."
  end

  private

  def set_card
    scryfall_id = params[:scryfall_id]

    response = CardSearch.conn.get("/cards/#{scryfall_id}")
    @card_data = JSON.parse(response.body)
  end

  def set_collection_card
    @collection_card = CollectionCard.find(params[:id])
  end

  def collection_card_params
    params.expect(collection_card: [:collection_id, :quantity, :condition, :foil, :price_paid, :acquired_at])
  end
end
