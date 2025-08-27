module LoggingConcern
  extend ActiveSupport::Concern

  private

  def log_user_action(action, details = {})
    Rails.logger.info "User Action: #{@current_user&.name} (#{@current_user&.role}) - #{action} - #{details}"
  end

  def log_error(error, context = {})
    Rails.logger.error "Error: #{error.message} - Context: #{context} - User: #{@current_user&.name}"
  end

  def log_performance(operation, duration)
    Rails.logger.info "Performance: #{operation} took #{duration}ms"
  end
end
