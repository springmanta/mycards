class DebugController < ApplicationController
  # Allow access without authentication for debugging
  skip_before_action :require_authentication, only: [:session]
  
  def session
    debug_info = {
      user_agent: request.user_agent,
      ip_address: request.remote_ip,
      session_cookie: cookies.signed[:session_id],
      session_cookie_raw: cookies[:session_id],
      current_session: Current.session&.id,
      current_user: Current.user&.email_address,
      authenticated: Current.authenticated?,
      cookies: request.cookies,
      headers: request.headers.to_h.select { |k, v| k.start_with?('HTTP_') }
    }
    
    render json: debug_info
  end
end