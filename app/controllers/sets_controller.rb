class SetsController < ApplicationController
  allow_unauthenticated_access

  def index
    @sets = MagicSet.order(name: :asc)
  end

  def show
    @set = MagicSet.find_by!(code: params[:code])
    @cards = @set.bulk_cards.order(:collector_number)
  end
end
