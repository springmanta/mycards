module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?, :current_user, :user_signed_in?
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
    rescue => e
      # Log the error but don't let it crash the app
      Rails.logger.error "Authentication error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    rescue => e
      # Log session resumption errors but don't crash
      Rails.logger.error "Session resumption error: #{e.message}"
      nil
    end

    def current_user
      Current.session&.user
    end

    def user_signed_in?
      current_user.present?
    end

    def find_session_by_cookie
      return nil unless cookies.signed[:session_id]
      
      session = Session.find_by(id: cookies.signed[:session_id])
      return nil unless session
      
      # Update session timestamp to keep it alive
      session.touch
      session
    rescue ActiveRecord::RecordNotFound
      # Clean up invalid session cookie
      cookies.delete(:session_id)
      nil
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_path
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        # Use more permissive cookie settings for better cross-device compatibility
        cookies.signed.permanent[:session_id] = { 
          value: session.id, 
          httponly: true, 
          same_site: :none,  # Allow cross-site requests for mobile compatibility
          secure: Rails.env.production?  # Only require secure in production
        }
      end
    end

    def terminate_session
      if Current.session
        Current.session.destroy
        Current.session = nil
      end
      cookies.delete(:session_id)
    rescue => e
      # Even if session destruction fails, clear the cookie
      Rails.logger.error "Session termination error: #{e.message}"
      cookies.delete(:session_id)
      Current.session = nil
    end
end
