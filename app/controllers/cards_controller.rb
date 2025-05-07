class CardsController < ApplicationController
  before_action :set_card, only: [ :show, :destroy, :edit, :update ]

  def index
    @cards = Card.all
  end

  def collection
    @cards = Card.all
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @card }
    end
  end

  def new
    @card = Card.new
  end

  def import
    scryfall_id = params.dig(:scryfall_search, :id)
    quantity = params.dig(:scryfall_search, :quantity).to_i
    quantity = 1 if quantity < 1

    @card = CardImporter.import_by_id(scryfall_id, quantity)

    if @card.present?
      redirect_to @card, notice: "Card imported successfully! Quantity: #{@card.quantity}"
    else
      redirect_to new_card_path, alert: "Could not import card."
    end
  end

  def search
    query = params[:q]
    scryfall = ScryfallApi.new
    results = scryfall.search_cards(query)

    cards = results.map do |card|
      image_url = card.dig("image_uris", "small")
      next unless image_url && card["name"] && card["id"]

      {
        id: card["id"],
        name: card["name"],
        image: image_url
      }
    end.compact

    render json: cards
  end

  def card_versions
    card_name = params[:name]
    scryfall = ScryfallApi.new
    results = scryfall.get_card_prints(card_name)

    versions = results.map do |card|
      image_url = card.dig("image_uris", "small")
      next unless image_url && card["id"]

      {
        id: card["id"],
        set: card["set"],
        set_name: card["set_name"],
        collector_number: card["collector_number"],
        rarity: card["rarity"],
        image: image_url,
        artist: card["artist"]
      }
    end.compact

    render json: versions
  end


  def destroy
    @card.destroy
    redirect_to cards_path, status: :see_other
  end

  def edit
  end

  def update
    # Check if scryfall_id is being changed
    if params[:card][:scryfall_id].present? && params[:card][:scryfall_id] != @card.scryfall_id
      # Update card version using CardImporter
      @card = CardImporter.update_card_version(@card, params[:card][:scryfall_id])

      # Update quantity separately if provided
      @card.update(quantity: params[:card][:quantity]) if params[:card][:quantity].present?

      if @card
        redirect_to @card, notice: "Card was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    else
      # Regular update for other attributes
      if @card.update(card_params)
        redirect_to @card, notice: "Card was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  private
  def card_params
    params.require(:card).permit(:name, :colors, :cmc, :card_type, :photo_url, :quantity, :scryfall_id)
  end

  def set_card
    @card = Card.find(params[:id])
  end
end
