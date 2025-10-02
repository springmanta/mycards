class CollectionCardsController < ApplicationController
  before_action :set_card, only: [:new, :create]
  before_action :set_collection_card, only: [:edit, :update, :destroy]

  def index
    @collections = Current.user.collections.includes(collection_cards: :card)
    @collection_cards = @collections.flat_map(&:collection_cards).sort_by(&:created_at).reverse
    @collection = @collections.first
    @view_mode = params[:view] || 'list'
  end

  def new
    @collection_card = CollectionCard.new(quantity: 1, condition: "near_mint", foil: false)
    @collections = Current.user.collections
  end

  def create
    @card = Card.find_or_create_by(scryfall_id: @card_data["id"]) do |card|
      card.name = @card_data["name"]
      card.set_name = @card_data["set_name"]
      card.set_code = @card_data["set"]
      card.rarity = @card_data["rarity"]
      card.mana_cost = @card_data["mana_cost"]
      card.type_line = @card_data["type_line"]
      card.oracle_text = @card_data["oracle_text"]
      card.image_url = @card_data.dig("image_uris", "normal")
      card.power = @card_data["power"]
      card.toughness = @card_data["toughness"]
    end

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
