class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      begin
        start_new_session_for user
        redirect_to after_authentication_url
      rescue => e
        Rails.logger.error("Session creation failed: #{e.message}")
        redirect_to new_session_path, alert: "Unable to create session. Please try again."
      end
    else
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    begin
      terminate_session
      redirect_to root_path
    rescue => e
      Rails.logger.error("Session termination failed: #{e.message}")
      redirect_to root_path, alert: "There was an issue logging out. Please try again."
    end
  end
end
