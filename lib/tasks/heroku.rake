namespace :heroku do
  desc "Tasks for Heroku deployment"

  task :setup_database => :environment do
    puts "Setting up database for Heroku deployment..."

    if ENV['DATABASE_URL']
      puts "DATABASE_URL is set"

      # Test the connection
      begin
        # Use the DATABASE_URL directly
        ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])

        # Test the connection
        ActiveRecord::Base.connection.execute("SELECT 1")
        puts "Database connection successful!"
      rescue => e
        puts "Error connecting to database: #{e.message}"
        puts "Backtrace: #{e.backtrace.join("\n")}"
      end
    else
      puts "DATABASE_URL is not set!"
    end
  end

  desc "Prepare database for migration"
  task :prepare_db => :environment do
    puts "Preparing database for migration..."

    # Disable the solid_queue, solid_cache, and solid_cable
    ENV['DISABLE_SOLID_QUEUE'] = 'true'
    ENV['DISABLE_SOLID_CACHE'] = 'true'
    ENV['DISABLE_SOLID_CABLE'] = 'true'

    # Set up the database connection
    Rake::Task["heroku:setup_database"].invoke
  end
end
