class Session < ApplicationRecord
  belongs_to :user

  def self.sweep(time = 1.hour)
    where(updated_at: ...time.ago).or(where(created_at: ...2.days.ago)).delete_all
  end

end
