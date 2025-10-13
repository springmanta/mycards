class MagicSet < ApplicationRecord
  has_many :bulk_cards, foreign_key: "set_code", primary_key: "code"
end
