class Card < ApplicationRecord
  has_many :collection_cards, dependent: :destroy
  has_many :collections, through: :collection_cards
  has_many :card_tags, dependent: :destroy
  has_many :tags, through: :card_tags

  validates :scryfall_id, presence: true, uniqueness: true
  validates :name, presence: true
end
