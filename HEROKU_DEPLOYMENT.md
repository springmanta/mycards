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
./bin/heroku-deploy
```

This script:
1. Sets the environment variables
2. Commits the changes
3. Pushes to Heroku
4. Runs database migrations

### 5. Run Database Migrations Manually (if needed)

If you need to run database migrations manually, use the provided script:

```bash
./bin/heroku-db-migrate
```

## Troubleshooting

### Database Connection Issues

If you encounter database connection issues, try the following:

1. Check if the PostgreSQL add-on is properly provisioned:

```bash
heroku addons | grep postgresql
```

2. Check the DATABASE_URL environment variable:

```bash
heroku config | grep DATABASE_URL
```

3. Run the database setup task:

```bash
heroku run rake heroku:setup_database
```

4. Restart the application:

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

- `config/database.yml`: Configured to use the DATABASE_URL environment variable
- `config/database.yml.erb`: Template for generating database.yml
- `config/environments/production.rb`: Configured to use memory store and async queue adapter
- `config/cable.yml`: Configured to use async adapter
- `config/initializers/database_connection.rb`: Ensures proper database connection
- `Procfile`: Runs the database setup task before starting the web server
- `Procfile.release`: Runs the database setup task during the release phase
- `.env`: Contains environment variables for local development
- `lib/tasks/heroku.rake`: Contains Rake tasks for Heroku deployment

## Scripts

The following scripts have been created to help with deployment:

- `bin/heroku-set-env`: Sets the necessary environment variables on Heroku
- `bin/heroku-db-migrate`: Runs database migrations on Heroku
- `bin/heroku-deploy`: Deploys the application to Heroku
