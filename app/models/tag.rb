class Tag < ApplicationRecord
  has_many :card_tags, dependent: :destroy
  has_many :cards, through: :card_tags

  validates :name, presence: true, uniqueness: true
end
