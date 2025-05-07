# This initializer ensures that the DATABASE_URL environment variable is properly used
# for the database connection in production.

if Rails.env.production? && ENV['DATABASE_URL']
  # Let Rails use the DATABASE_URL environment variable directly
  # This is the recommended approach for Heroku
  Rails.application.config.after_initialize do
    ActiveRecord::Base.connection_pool.disconnect!
    ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
  end
end
