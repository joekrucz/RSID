# Environment Variables Configuration
# This file documents all environment variables used by the application

module EnvironmentVariables
  # Database Configuration
  DATABASE_HOST = ENV.fetch('DATABASE_HOST', 'localhost')
  DATABASE_PORT = ENV.fetch('DATABASE_PORT', 5432)
  DATABASE_USERNAME = ENV.fetch('DATABASE_USERNAME', 'postgres')
  DATABASE_PASSWORD = ENV.fetch('DATABASE_PASSWORD', '')
  DATABASE_URL = ENV.fetch('DATABASE_URL', nil)
  
  # Application Configuration
  APP_VERSION = ENV.fetch('APP_VERSION', '1.0.0')
  RAILS_ENV = ENV.fetch('RAILS_ENV', 'development')
  RAILS_LOG_LEVEL = ENV.fetch('RAILS_LOG_LEVEL', 'info')
  RAILS_MAX_THREADS = ENV.fetch('RAILS_MAX_THREADS', 5)
  
  # Security Configuration
  MAX_SEARCH_RESULTS = ENV.fetch('MAX_SEARCH_RESULTS', 100).to_i
  SESSION_TIMEOUT = ENV.fetch('SESSION_TIMEOUT', 24.hours).to_i
  
  # Performance Configuration
  ENABLE_PERFORMANCE_MONITORING = ENV.fetch('ENABLE_PERFORMANCE_MONITORING', Rails.env.production?).to_s == 'true'
  
  # Feature Flags
  FEATURE_FLAGS_ENABLED = ENV.fetch('FEATURE_FLAGS_ENABLED', true).to_s == 'true'
  
  # Cache Configuration
  REDIS_URL = ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')
  
  # Email Configuration
  SMTP_HOST = ENV.fetch('SMTP_HOST', nil)
  SMTP_PORT = ENV.fetch('SMTP_PORT', 587)
  SMTP_USERNAME = ENV.fetch('SMTP_USERNAME', nil)
  SMTP_PASSWORD = ENV.fetch('SMTP_PASSWORD', nil)
  
  # External Services
  AWS_ACCESS_KEY_ID = ENV.fetch('AWS_ACCESS_KEY_ID', nil)
  AWS_SECRET_ACCESS_KEY = ENV.fetch('AWS_SECRET_ACCESS_KEY', nil)
  AWS_REGION = ENV.fetch('AWS_REGION', 'us-east-1')
  AWS_S3_BUCKET = ENV.fetch('AWS_S3_BUCKET', nil)
  
  # Monitoring
  SENTRY_DSN = ENV.fetch('SENTRY_DSN', nil)
  NEW_RELIC_LICENSE_KEY = ENV.fetch('NEW_RELIC_LICENSE_KEY', nil)
end
