class CardsController < ApplicationController
  before_action :set_card, only: [:show, :update, :destroy]

  def index
    @cards = Card.all
  end

  def show
  end

  def new
    @card = Card.new
  end

  def create
    @card = Card.new(card_params)
    if @card.save
      redirect_to @card, notice: 'Card was successfully created.'
    else
      render :new, status: :unprocessable_entity
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
    params.require(:card).permit(:name, :colors, :convertedManaCost, :card_type, :photo_url)
  end

  def set_card
    @card = Card.find(params[:id])
  end
end
