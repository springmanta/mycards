class CollectionsController < ApplicationController
  before_action :set_collection, only: [:show, :edit, :update, :destroy]

  def index
    @collections = Current.user.collections.includes(collection_cards: :card)
  end

  def show
    @collection_cards = @collection.collection_cards.includes(:card)
    @view_mode = params[:view] || 'list'

    if params[:q].present?
      @collection_cards = @collection_cards.select { |cc| cc.card.name.downcase.include?(params[:q].downcase) }
    end

    if params[:rarity].present?
      @collection_cards = @collection_cards.select { |cc| cc.card.rarity == params[:rarity] }
    end

    @collection_cards = case params[:sort]
    when 'name_asc' then @collection_cards.sort_by { |cc| cc.card.name }
    when 'name_desc' then @collection_cards.sort_by { |cc| cc.card.name }.reverse
    when 'price_asc' then @collection_cards.sort_by { |cc| cc.card.cardmarket_price || 0 }
    when 'price_desc' then @collection_cards.sort_by { |cc| cc.card.cardmarket_price || 0 }.reverse
    else @collection_cards.sort_by(&:created_at).reverse
    end
  end

  def new
    @collection = Collection.new
  end

  def create
    @collection = Current.user.collections.build(collection_params)

    if @collection.save
      redirect_to collections_path, notice: "#{@collection.name} created!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @collection.update(collection_params)
      redirect_to @collection, notice: "#{@collection.name} updated!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @collection.name
    @collection.destroy
    redirect_to collections_path, notice: "#{name} deleted."
  end

  private

  def set_collection
    @collection = Current.user.collections.find(params[:id])
  end

  def collection_params
    params.expect(collection: [:name, :description])
  end
end
