class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Method
  before_action :resume_session
  
  # Allow modern browsers but be more lenient with mobile browsers
  # This prevents 500 errors when accessing from mobile devices
  allow_browser versions: :modern, only: -> { 
    # Skip browser check for mobile browsers - they often have different version patterns
    !request.user_agent&.match?(/Mobile|Android|iPhone|iPad|iPod|BlackBerry|Opera Mini/i)
  }
end
