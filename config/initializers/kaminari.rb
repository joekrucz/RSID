# Kaminari configuration
Kaminari.configure do |config|
  # Default per page
  config.default_per_page = 25
  
  # Max per page
  config.max_per_page = 100
  
  # Page method name
  config.page_method_name = :page
  
  # Param name
  config.param_name = :page
end
