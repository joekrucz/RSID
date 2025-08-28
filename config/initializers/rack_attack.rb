# class Rack::Attack
#   # Rate limiting for search endpoints
#   throttle('search/ip', limit: 60, period: 1.minute) do |request|
#     if request.path.start_with?('/search')
#       request.ip
#     end
#   end

#   # Rate limiting for login attempts
#   throttle('login/ip', limit: 5, period: 5.minutes) do |request|
#     if request.path == '/login' && request.post?
#       request.ip
#     end
#   end

#   # Rate limiting for API endpoints
#   throttle('api/ip', limit: 300, period: 5.minutes) do |request|
#     if request.path.start_with?('/api/')
#       request.ip
#     end
#   end

#   # Block suspicious requests
#   blocklist('block suspicious requests') do |request|
#     # Block requests with suspicious user agents
#     suspicious_user_agents = [
#       /bot/i,
#       /crawler/i,
#       /spider/i,
#       /scraper/i
#     ]
    
#     user_agent = request.user_agent.to_s
#     suspicious_user_agents.any? { |pattern| user_agent.match?(pattern) }
#   end

#   # Custom response for blocked requests
#   self.blocklisted_responder = lambda do |env|
#     [429, {'Content-Type' => 'application/json'}, [{error: 'Too many requests'}.to_json]]
#   end

#   # Custom response for throttled requests
#   self.throttled_responder = lambda do |env|
#     [429, {'Content-Type' => 'application/json'}, [{error: 'Rate limit exceeded'}.to_json]]
#   end
# end
