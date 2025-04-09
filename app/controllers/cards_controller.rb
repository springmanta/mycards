class CardsController < ApplicationController
  before_action :set_card, only: [ :show, :destroy ]

  def index
    @cards = Card.all
  end

  def show
  end

  def new
    @card = Card.new
  end

  def import
    card_name = params.dig(:scryfall_search, :name)
    @card = CardImporter.import_by_name(card_name)

    if @card.present?
      redirect_to @card, notice: "Card imported successfully!"
    else
      flash.now[:alert] = "Could not find card from Scryfall."
      render :new, status: :unprocessable_entity
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
