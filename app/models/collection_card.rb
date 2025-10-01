class CollectionCard < ApplicationRecord
  belongs_to :collection
  belongs_to :card

  CONDITIONS = %w[near_mint lightly_played good moderately_played heavily_played damaged]

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :condition, presence: true, inclusion: { in: CONDITIONS }
  validates :foil, inclusion: { in: [true, false] }

end
