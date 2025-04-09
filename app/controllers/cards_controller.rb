class CardsController < ApplicationController
  before_action :set_card, only: [:show, :edit, :update, :destroy]

  def index
    @cards = Card.all
  end

  def show
  end

  def new
    @card = Card.new
  end

  def create_from_scryfall
    card_name = params.dig(:scryfall_search, :name)
    @card = Card.from_scryfall(card_name)

    if @card.persisted?
      redirect_to @card, notice: "Card imported successfully!"
    else
      flash.now[:alert] = "Could not find card from Scryfall."
      render :new, status: :unprocessable_entity
    end
  end


  def edit
    respond_to do |format|
      format.html
      format.js
    end
  end

  def update
    if @card.update(card_params)
      redirect_to @card, notice: 'Card was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @card.destroy
    redirect_to cards_path, status: :see_other
  end

  private
  def card_params
    params.require(:card).permit(:name, :colors, :cmc, :card_type, :photo_url)
  end

  def set_card
    @card = Card.find(params[:id])
  end
end
