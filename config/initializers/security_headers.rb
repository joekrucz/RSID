# Security headers configuration
Rails.application.config.middleware.use(Rack::Deflater)

# Add security headers
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'  # Configure this properly for production
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end

# Custom security headers middleware
class SecurityHeaders
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)
    
    # Add security headers
    headers['X-Frame-Options'] = 'SAMEORIGIN'
    headers['X-Content-Type-Options'] = 'nosniff'
    headers['X-XSS-Protection'] = '1; mode=block'
    headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    headers['Permissions-Policy'] = 'geolocation=(), microphone=(), camera=()'
    
    # HSTS header (only in production)
    if Rails.env.production?
      headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains; preload'
    end
    
    [status, headers, response]
  end
end

Rails.application.config.middleware.use SecurityHeaders
