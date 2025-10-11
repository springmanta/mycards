#!/usr/bin/env ruby
# Debug script to help identify session synchronization issues
# Run this script to check session-related configurations

puts "=== Session Debug Information ==="
puts "Rails Environment: #{Rails.env}"
puts "Rails Version: #{Rails.version}"

puts "\n=== Cookie Configuration ==="
puts "Default cookie options:"
puts "  - httponly: true"
puts "  - same_site: #{Rails.env.production? ? ':none (with secure: true)' : ':lax'}"

puts "\n=== Database Configuration ==="
puts "Database adapter: #{Rails.application.config.database_configuration[Rails.env]['adapter']}"

puts "\n=== Session Table Structure ==="
if defined?(Session)
  puts "Session model exists"
  puts "Session attributes: #{Session.column_names.join(', ')}"
  
  # Check if there are any sessions in the database
  begin
    session_count = Session.count
    puts "Total sessions in database: #{session_count}"
    
    if session_count > 0
      recent_sessions = Session.order(created_at: :desc).limit(3)
      puts "\nRecent sessions:"
      recent_sessions.each do |session|
        puts "  - ID: #{session.id}, User: #{session.user&.email_address}, Created: #{session.created_at}"
        puts "    User Agent: #{session.user_agent&.truncate(50)}"
        puts "    IP Address: #{session.ip_address}"
      end
    end
  rescue => e
    puts "Error accessing sessions: #{e.message}"
  end
else
  puts "Session model not found"
end

puts "\n=== Potential Issues to Check ==="
puts "1. Cookie SameSite policy - currently set to #{Rails.env.production? ? ':none' : ':lax'}"
puts "2. HTTPS requirement - SameSite :none requires HTTPS in production"
puts "3. Cross-domain access - ensure both devices access the same domain"
puts "4. Cookie expiration - check if sessions are being cleaned up too aggressively"
puts "5. User agent validation - check if there's any middleware validating user agents"

puts "\n=== Debugging Steps ==="
puts "1. Check Rails logs for session-related errors"
puts "2. Verify cookie is being set correctly on PC login"
puts "3. Check if cookie is being sent from mobile device"
puts "4. Verify database connectivity from both devices"
puts "5. Check for any middleware that might be interfering with session handling"