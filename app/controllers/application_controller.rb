class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Method
  before_action :resume_session
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  # Debug endpoint for session troubleshooting
  def session_debug
    if Rails.env.development? || Rails.env.test?
      render json: {
        session_id: cookies.signed[:session_id],
        current_session: Current.session&.id,
        current_user: Current.user&.email_address,
        user_agent: request.user_agent,
        ip_address: request.remote_ip,
        cookies: request.cookies.keys,
        timestamp: Time.current
      }
    else
      head :not_found
    end
  end
end
