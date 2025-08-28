module PerformanceMonitoringConcern
  extend ActiveSupport::Concern
  
  included do
    around_action :monitor_performance
  end
  
  private
  
  def monitor_performance
    start_time = Time.current
    start_memory = memory_usage
    
    yield
    
    end_time = Time.current
    end_memory = memory_usage
    
    duration = (end_time - start_time) * 1000 # Convert to milliseconds
    memory_delta = end_memory - start_memory
    
    # Log performance metrics
    log_performance_metrics(duration, memory_delta)
    
    # Add performance headers
    response.headers['X-Response-Time'] = "#{duration.round(2)}ms"
    response.headers['X-Memory-Usage'] = "#{end_memory}MB"
  rescue => e
    # If performance monitoring fails, still yield the request
    Rails.logger.warn("Performance monitoring failed: #{e.message}")
    yield
  end
  
  def log_performance_metrics(duration, memory_delta)
    return unless Rails.application.config.x.enable_performance_monitoring
    
    Rails.logger.info(
      "Performance: #{request.method} #{request.path} - " \
      "Duration: #{duration.round(2)}ms, " \
      "Memory: #{memory_delta.round(2)}MB, " \
      "User: #{@current_user&.id || 'anonymous'}"
    )
    
    # Alert on slow requests (over 1 second)
    if duration > 1000
      Rails.logger.warn(
        "SLOW REQUEST: #{request.method} #{request.path} - " \
        "Duration: #{duration.round(2)}ms"
      )
    end
  end
  
  def memory_usage
    # Get memory usage in MB
    if defined?(GetProcessMem)
      GetProcessMem.new.mb
    else
      # Fallback for systems without get_process_mem gem
      begin
        `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
      rescue
        0.0
      end
    end
  rescue
    0.0
  end
end
