class BulkCard < ApplicationRecord
  validates :scryfall_id, presence: true, uniqueness: true
  validates :name, presence: true

  belongs_to :magic_set, foreign_key: "set_code", primary_key: "code", optional: true

  def self.search_by_nam(query)
    where("name ILIKE ?", "%#{query}%").limit(20)
  end

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
