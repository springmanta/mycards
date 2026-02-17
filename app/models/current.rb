class Current < ActiveSupport::CurrentAttributes
  attribute :session
  delegate :user, to: :session, allow_nil: true
  
  # Add debugging method
  def session_info
    return "No session" unless session
    
    {
      id: session.id,
      user_email: user&.email_address,
      created_at: session.created_at,
      updated_at: session.updated_at
    }
  end
end
