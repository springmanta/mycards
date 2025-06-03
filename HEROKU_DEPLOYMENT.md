# Heroku Deployment Guide

This guide provides instructions on how to deploy this Rails application to Heroku.

## Prerequisites

- Heroku CLI installed
- Git installed
- Heroku account

## Deployment Steps

### 1. Create a Heroku App

```bash
heroku create mycards
```

### 2. Add PostgreSQL Add-on

```bash
heroku addons:create heroku-postgresql:mini
```

### 3. Set Environment Variables

Run the provided script to set the necessary environment variables:

```bash
./bin/heroku-set-env
```

This script sets the following environment variables:
- `DISABLE_SOLID_QUEUE=true`
- `DISABLE_SOLID_CACHE=true`
- `DISABLE_SOLID_CABLE=true`
- `DISABLE_DATABASE_ENVIRONMENT_CHECK=1`
- `RAILS_ENV=production`
- `RACK_ENV=production`
- `RAILS_LOG_LEVEL=info`
- `FORCE_SSL=true`

### 4. Deploy the Application

Run the provided script to deploy the application:

```bash
§```

This script:
1. Sets the environment variables
2. Commits the changes
3. Pushes to Heroku
4. Runs database migrations

### 5. Run Database Migrations

If you need to run database migrations, use one of the provided scripts:

#### Standard Migration

```bash
./bin/heroku-db-migrate
```

#### Direct Migration (Recommended)

This approach directly uses the DATABASE_URL environment variable:

```bash
./bin/heroku-direct-migrate
```

### 6. Check Database Configuration

To check the database configuration on Heroku:

```bash
./bin/heroku-check-db
```

This script:
1. Checks if the PostgreSQL add-on is properly provisioned
2. Checks the DATABASE_URL environment variable
3. Checks if the database exists
4. Tests the database connection

### 7. Reset Database (if needed)

If you need to reset the database on Heroku:

```bash
./bin/heroku-reset-db
```

This script:
1. Resets the database
2. Runs migrations
3. Optionally seeds the database

## Troubleshooting

### Database Connection Issues

If you encounter database connection issues, try the following:

1. Check the database configuration:

```bash
./bin/heroku-check-db
```

2. Make sure the PostgreSQL add-on is properly provisioned:

```bash
heroku addons | grep postgresql
```

3. Check the DATABASE_URL environment variable:

```bash
heroku config:get DATABASE_URL
```

4. Try the direct migration approach:

```bash
./bin/heroku-direct-migrate
```

5. Reset the database (if necessary):

```bash
./bin/heroku-reset-db
```

6. Restart the application:

```bash
heroku restart
```

### Logs

Check the logs for any errors:

```bash
heroku logs --tail
```

## Configuration Files

The following files have been modified to ensure proper deployment to Heroku:

- `config/database.yml`: Simplified to directly use the DATABASE_URL environment variable
- `config/database.yml.erb`: Template for generating database.yml
- `config/environments/production.rb`: Configured to conditionally use memory store and async queue adapter
- `config/cable.yml`: Configured to conditionally use async adapter
- `config/initializers/database_connection.rb`: Ensures proper database connection using DATABASE_URL
- `Procfile`: Runs the database setup task before starting the web server
- `Procfile.release`: Runs the database setup task during the release phase
- `.env`: Contains environment variables for local development
- `lib/tasks/heroku.rake`: Contains simplified Rake tasks for Heroku deployment

## Scripts

The following scripts have been created to help with deployment:

### General Scripts

- `bin/heroku-set-env`: Sets the necessary environment variables on Heroku
- `bin/heroku-db-migrate`: Runs database migrations on Heroku
- `bin/heroku-direct-migrate`: Runs database migrations using DATABASE_URL directly
- `bin/heroku-check-db`: Checks the database configuration on Heroku
- `bin/heroku-reset-db`: Resets the database on Heroku
- `bin/heroku-deploy`: Deploys the application to Heroku
- `bin/heroku-update-gemfile`: Updates the Gemfile.lock file for Heroku deployment
- `bin/heroku-deploy-with-gemfile-update`: Deploys the application with Gemfile updates

### App-Specific Scripts

The following scripts are specifically for the "shrouded-eyrie-38835" Heroku app:

- `bin/heroku-connect`: Connects to the existing Heroku app and sets up the environment
- `bin/heroku-deploy-app`: Deploys the application to the specific Heroku app
- `bin/heroku-migrate-app`: Runs migrations on the specific Heroku app
- `bin/heroku-logs`: Shows the logs for the specific Heroku app
- `bin/heroku-check-migrations`: Checks the migration status on the specific Heroku app
- `bin/heroku-setup-and-migrate`: Sets up the database and runs migrations on the specific Heroku app
- `bin/heroku-deploy-fix`: Deploys fixes for the view and controller to the specific Heroku app
- `bin/heroku-full-fix`: Applies all fixes, resets the database, and runs migrations on the specific Heroku app

## Gemfile Changes

The Gemfile has been modified to move the solid_cache, solid_queue, and solid_cable gems to the development and test environments only. This prevents these gems from being loaded in production, which can cause issues with Heroku deployment.

### Deploying with Gemfile Updates

To deploy the application with the updated Gemfile, run:

```bash
./bin/heroku-deploy-with-gemfile-update
```

This script:
1. Sets environment variables
2. Updates the Gemfile.lock file
3. Runs database migrations
4. Restarts the application

### Updating Gemfile.lock Only

If you only need to update the Gemfile.lock file, run:

```bash
./bin/heroku-update-gemfile
```

This script:
1. Commits the changes to the Gemfile
2. Updates the Gemfile.lock file
3. Commits the changes to the Gemfile.lock file
4. Pushes to Heroku
