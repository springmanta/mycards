module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
      validate_and_cleanup_session if Current.session
    end

    def find_session_by_cookie
      return nil unless cookies.signed[:session_id]
      
      begin
        session_id = cookies.signed[:session_id]
        # Validate session ID format
        unless session_id.is_a?(Integer) && session_id > 0
          Rails.logger.warn("Invalid session ID format: #{session_id}, User Agent: #{request.user_agent}")
          cookies.delete(:session_id)
          return nil
        end
        
        session = Session.find_by(id: session_id)
        if session
          Rails.logger.info("Session found for user: #{session.user&.email_address}, User Agent: #{request.user_agent}")
        else
          Rails.logger.warn("Session not found for ID: #{session_id}, User Agent: #{request.user_agent}")
        end
        session
      rescue ActiveRecord::RecordNotFound, ActiveRecord::StatementInvalid => e
        Rails.logger.error("Session lookup failed: #{e.message}, User Agent: #{request.user_agent}")
        # Clear the invalid session cookie
        cookies.delete(:session_id)
        nil
      rescue => e
        Rails.logger.error("Unexpected error in session lookup: #{e.message}, User Agent: #{request.user_agent}")
        cookies.delete(:session_id)
        nil
      end
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_path
    end

    def start_new_session_for(user)
      begin
        user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
          Current.session = session
          # Set cookie with mobile-friendly settings
          cookie_options = {
            value: session.id,
            httponly: true,
            same_site: :lax,
            secure: Rails.env.production?,
            expires: 30.days.from_now
          }
          cookies.signed[:session_id] = cookie_options
          Rails.logger.info("Session created for user: #{user.email_address}, User Agent: #{request.user_agent}")
        end
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error("Failed to create session: #{e.message}")
        raise
      end
    end

    def terminate_session
      if Current.session
        begin
          Current.session.destroy
        rescue ActiveRecord::RecordNotFound => e
          Rails.logger.warn("Session already destroyed: #{e.message}")
        end
      end
      cookies.delete(:session_id)
      Current.session = nil
    end

    def validate_and_cleanup_session
      return unless Current.session
      
      # Check if session is still valid (not expired)
      if Current.session.updated_at < 1.hour.ago || Current.session.created_at < 2.days.ago
        Rails.logger.info("Session expired, cleaning up")
        terminate_session
        return
      end
      
      # Check if user still exists
      unless Current.session.user
        Rails.logger.warn("Session user not found, cleaning up")
        terminate_session
        return
      end
      
      # Update session timestamp
      Current.session.touch
    end
end
