class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :collections, dependent: :destroy

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8 }, allow_blank: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def ensure_collection
    base_name = "My Collection"
    existing_count = collections.where("name LIKE ?", "#{base_name}%").count

    if existing_count == 0
      collections.create!(name: base_name)
    else
      collections.create!(name: "#{base_name} #{existing_count + 1}")
    end
  end
end
