class Rack::Attack
  # Temporarily disable rate limiting for development
  if Rails.env.development?
    # Allow all requests in development
  else
    # Rate limiting for search endpoints
    throttle('search/ip', limit: 60, period: 1.minute) do |request|
      if request.path.start_with?('/search') || request.path.include?('search=')
        request.ip
      end
    end

    # Rate limiting for login attempts
    throttle('login/ip', limit: 5, period: 5.minutes) do |request|
      if request.path == '/login' && request.post?
        request.ip
      end
    end

    # Rate limiting for general requests
    throttle('req/ip', limit: 300, period: 5.minutes) do |request|
      request.ip
    end

    # Rate limiting for grant applications (more restrictive)
    throttle('grant_apps/ip', limit: 100, period: 1.minute) do |request|
      if request.path.start_with?('/grant_applications')
        request.ip
      end
    end

    # Block suspicious requests
    blocklist('block suspicious requests') do |request|
      # Block requests with suspicious user agents
      suspicious_user_agents = [
        /bot/i,
        /crawler/i,
        /spider/i,
        /scraper/i,
        /curl/i,
        /wget/i
      ]
      
      user_agent = request.user_agent.to_s
      suspicious_user_agents.any? { |pattern| user_agent.match?(pattern) }
    end

    # Custom response for blocked requests
    self.blocklisted_responder = lambda do |env|
      [429, {'Content-Type' => 'application/json'}, [{error: 'Too many requests'}.to_json]]
    end

    # Custom response for throttled requests
    self.throttled_responder = lambda do |env|
      [429, {'Content-Type' => 'application/json'}, [{error: 'Rate limit exceeded'}.to_json]]
    end
  end
end
