class BulkCard < ApplicationRecord
  validates :scryfall_id, presence: true, uniqueness: true
  validates :name, presence: true

  scope :search_by_name, ->(query) {
    where("lower(name) LIKE ?", "%#{query.downcase}%")
      .order(:name)
      .limit(20)
  }

  scope :printings_of, ->(card_name) {
    where("lower(name) = ?", card_name.downcase)
      .order(:set_code, :collector_number)
  }
end
