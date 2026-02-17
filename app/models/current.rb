class Current < ActiveSupport::CurrentAttributes
  attribute :session
  delegate :user, to: :session, allow_nil: true
  
  def authenticated?
    session.present? && user.present?
  end
end
