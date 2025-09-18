# Security validation for environment variables
Rails.application.configure do
  if Rails.env.production?
    # Required environment variables for production
    required_vars = %w[SECRET_KEY_BASE]
    missing_vars = required_vars.select { |var| ENV[var].blank? }
    
    if missing_vars.any?
      raise "Missing required environment variables: #{missing_vars.join(', ')}"
    end
    
    # DATABASE_URL is provided by Railway automatically, so we just warn if it's missing
    if ENV['DATABASE_URL'].blank?
      Rails.logger.warn "DATABASE_URL not set - Railway should provide this automatically"
    end
    
    # Validate SECRET_KEY_BASE strength
    secret_key = ENV['SECRET_KEY_BASE']
    if secret_key && secret_key.length < 32
      raise "SECRET_KEY_BASE must be at least 32 characters long"
    end
    
    # Validate database URL format
    database_url = ENV['DATABASE_URL']
    if database_url && !database_url.match?(/\Apostgres:\/\/.+/)
      Rails.logger.warn "DATABASE_URL should use PostgreSQL in production"
    end
    
    # Check for development-specific variables that shouldn't be in production
    dev_vars = %w[RAILS_ENV development]
    dev_vars.each do |var|
      if ENV[var] == 'development'
        Rails.logger.warn "Environment variable #{var} is set to development in production"
      end
    end
  end
  
  # Development-specific validations
  if Rails.env.development?
    # Warn if SECRET_KEY_BASE is not set (will use fallback)
    if ENV['SECRET_KEY_BASE'].blank?
      Rails.logger.warn "SECRET_KEY_BASE not set in development - using fallback key"
    end
  end
end
