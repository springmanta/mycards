class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Method
  before_action :resume_session
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
  rescue_from StandardError, with: :handle_general_error

  private

  def handle_record_not_found(exception)
    Rails.logger.error("Record not found: #{exception.message}")
    redirect_to root_path, alert: "The requested resource was not found."
  end

  def handle_record_invalid(exception)
    Rails.logger.error("Record invalid: #{exception.message}")
    redirect_to root_path, alert: "There was an issue with the data. Please try again."
  end

  def handle_general_error(exception)
    Rails.logger.error("Unexpected error: #{exception.message}")
    Rails.logger.error("User Agent: #{request.user_agent}")
    Rails.logger.error("IP Address: #{request.remote_ip}")
    Rails.logger.error("Session ID: #{cookies.signed[:session_id]}")
    Rails.logger.error(exception.backtrace.join("\n"))
    redirect_to root_path, alert: "An unexpected error occurred. Please try again."
  end
end
