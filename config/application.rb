require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BlankCodebase
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0
    
    # Fallback for SECRET_KEY_BASE if not set in environment
    config.secret_key_base = ENV['SECRET_KEY_BASE'] || 'demo_rsid_app_2024_secure_key_for_demonstrations_only_do_not_use_in_production'

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    
    # Application version
    config.version = ENV.fetch('APP_VERSION', '1.0.0')
    
    # Environment-specific configuration
    config.x.app_name = 'RSID App'
    config.x.environment = Rails.env
    
    # Performance monitoring
    config.x.enable_performance_monitoring = Rails.env.production?
    
    # Feature flags
    config.x.feature_flags_enabled = true
    
    # Security settings
    config.x.max_search_results = ENV.fetch('MAX_SEARCH_RESULTS', 100).to_i
    config.x.session_timeout = ENV.fetch('SESSION_TIMEOUT', 24.hours).to_i
    
    # Kaminari pagination configuration
    config.x.kaminari_default_per_page = 25
    config.x.kaminari_max_per_page = 100
  end
end
