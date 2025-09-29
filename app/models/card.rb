class Card < ApplicationRecord
  has_many :collection_cards, dependent: :destroy
  has_many :collections, through: :collection_cards
  has_many :card_tags, dependent: :destroy
  has_many :tags, through: :card_tags
  has_one_attached :image
end
