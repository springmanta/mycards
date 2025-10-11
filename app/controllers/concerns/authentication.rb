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
    rescue => e
      Rails.logger.error "Session resume failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      nil
    end

    def find_session_by_cookie
      return nil unless cookies.signed[:session_id]
      
      begin
        session_id = cookies.signed[:session_id]
        Rails.logger.info "Attempting to find session with ID: #{session_id}"
        found_session = Session.find_by(id: session_id)
        
        if found_session
          Rails.logger.info "Session found for user: #{found_session.user.email_address}"
        else
          Rails.logger.warn "No session found for ID: #{session_id}"
        end
        
        found_session
      rescue => e
        Rails.logger.error "Session lookup failed: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
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
      Rails.logger.info "Creating new session for user: #{user.email_address}"
      Rails.logger.info "User agent: #{request.user_agent}"
      Rails.logger.info "IP address: #{request.remote_ip}"
      
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookie_options = {
          value: session.id, 
          httponly: true
        }
        
        # Use appropriate SameSite policy based on environment
        if Rails.env.production?
          cookie_options.merge!({
            same_site: :none,
            secure: true
          })
        else
          cookie_options.merge!({
            same_site: :lax
          })
        end
        
        Rails.logger.info "Setting session cookie with options: #{cookie_options}"
        cookies.signed.permanent[:session_id] = cookie_options
        Rails.logger.info "Session created with ID: #{session.id}"
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end
end
