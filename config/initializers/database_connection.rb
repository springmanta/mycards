# This initializer ensures that the DATABASE_URL environment variable is properly parsed
# and used for the database connection in production.

if Rails.env.production? && ENV['DATABASE_URL']
  require 'uri'

  # Parse the DATABASE_URL environment variable
  uri = URI.parse(ENV['DATABASE_URL'])

  # Override the database configuration with the parsed values
  Rails.application.config.after_initialize do
    ActiveRecord::Base.connection_pool.disconnect!

    ActiveRecord::Base.establish_connection(
      adapter: 'postgresql',
      host: uri.host,
      port: uri.port,
      database: uri.path.split('/')[1],
      username: uri.user,
      password: uri.password,
      pool: ENV.fetch("RAILS_MAX_THREADS") { 5 }
    )
  end
end
