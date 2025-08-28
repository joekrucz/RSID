class HealthController < ActionController::Base
  def index
    health_status = {
      status: 'healthy',
      timestamp: Time.current.iso8601,
      version: '1.0.0',
      environment: Rails.env
    }
    
    render json: health_status, status: 200
  end
  
  def database
    status = database_status
    render json: { database: status }, status: status[:healthy] ? 200 : 503
  end
  
  def cache
    status = cache_status
    render json: { cache: status }, status: status[:healthy] ? 200 : 503
  end
  
  private
  
  def database_status
    begin
      # Test database connection
      ActiveRecord::Base.connection.execute('SELECT 1')
      
      # Test a simple query (only if User table exists)
      if ActiveRecord::Base.connection.table_exists?('users')
        User.count
        {
          healthy: true,
          message: 'Database connection successful',
          tables: ActiveRecord::Base.connection.tables.count
        }
      else
        {
          healthy: true,
          message: 'Database connection successful (no tables yet)',
          tables: 0
        }
      end
    rescue => e
      {
        healthy: false,
        message: "Database error: #{e.message}",
        error: e.class.name
      }
    end
  end
  
  def cache_status
    begin
      # Test cache connection
      Rails.cache.write('health_check', 'ok', expires_in: 1.minute)
      value = Rails.cache.read('health_check')
      
      if value == 'ok'
        {
          healthy: true,
          message: 'Cache connection successful',
          type: Rails.cache.class.name
        }
      else
        {
          healthy: false,
          message: 'Cache read/write test failed'
        }
      end
    rescue => e
      {
        healthy: false,
        message: "Cache error: #{e.message}",
        error: e.class.name
      }
    end
  end
  
  def queue_status
    begin
      # Test queue connection (if using Active Job)
      if defined?(ActiveJob)
        {
          healthy: true,
          message: 'Queue system available',
          type: ActiveJob::Base.queue_adapter.class.name
        }
      else
        {
          healthy: true,
          message: 'No queue system configured'
        }
      end
    rescue => e
      {
        healthy: false,
        message: "Queue error: #{e.message}",
        error: e.class.name
      }
    end
  end
end
