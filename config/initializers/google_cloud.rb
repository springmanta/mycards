require "google/cloud/vision/v1"

Google::Cloud::Vision::V1::ImageAnnotator::Client.configure do |config|
  credentials = Rails.application.credentials.dig(:google_cloud, :credentials)
  config.credentials = credentials if credentials
end
