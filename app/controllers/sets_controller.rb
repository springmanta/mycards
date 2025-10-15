class SetsController < ApplicationController
  allow_unauthenticated_access

  def index
    @sets = MagicSet.all

    # Search by name
    if params[:q].present?
      @sets = @sets.where("name ILIKE ?", "%#{params[:q]}%")
    end

    # Filter by first letter
    if params[:letter].present?
      @sets = @sets.where("name ILIKE ?", "#{params[:letter]}%")
    end

    # Sorting
    @sets = case params[:sort]
    when 'name_desc'
      @sets.order(name: :desc)
    when 'released_asc'
      @sets.order(released_at: :asc, name: :asc)
    when 'released_desc'
      @sets.order(released_at: :desc, name: :asc)
    else
      @sets.order(name: :asc)
    end
  end

  def show
    @set = MagicSet.find_by!(code: params[:code])
    @cards = @set.bulk_cards

    # Search within set
    if params[:q].present?
      @cards = @cards.where("bulk_cards.name ILIKE ?", "%#{params[:q]}%")
    end

    # Filter by rarity
    if params[:rarity].present?
      @cards = @cards.where(rarity: params[:rarity])
    end

    # Filter by color
    if params[:color].present?
      @cards = @cards.where("metadata -> 'colors' @> ?", "[\"#{params[:color]}\"]")
    end

    # Sorting
    @cards = case params[:sort]
    when 'name_asc'
      @cards.order(name: :asc)
    when 'name_desc'
      @cards.order(name: :desc)
    when 'collector_desc'
      @cards.order(collector_number: :desc)
    else
      @cards.order(Arel.sql("CAST(NULLIF(regexp_replace(collector_number, '[^0-9]', '', 'g'), '') AS INTEGER) ASC"))
    end
  end
end
