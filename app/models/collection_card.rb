class CollectionCard < ApplicationRecord
  belongs_to :collection
  belongs_to :card

  CONDITIONS = %w[mint near_mint excellent good light_played played poor]

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :condition, presence: true, inclusion: { in: CONDITIONS }
  validates :foil, inclusion: { in: [true, false] }

end
