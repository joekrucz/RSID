namespace :debug do
  desc "Debug company associations in production"
  task company_associations: :environment do
    puts "=== Company Association Debug ==="
    puts "Environment: #{Rails.env}"
    puts "Database: #{ActiveRecord::Base.connection.current_database}"
    
    # Check if we have any users
    user_count = User.count
    puts "Total users: #{user_count}"
    
    if user_count > 0
      user = User.first
      puts "First user: #{user.name} (#{user.email})"
      
      # Check grant applications
      app_count = user.grant_applications.count
      puts "Grant applications for first user: #{app_count}"
      
      if app_count > 0
        # Check company associations
        apps_with_companies = user.grant_applications.joins(:company).count
        apps_without_companies = user.grant_applications.left_joins(:company).where(companies: { id: nil }).count
        
        puts "Applications with companies: #{apps_with_companies}"
        puts "Applications without companies: #{apps_without_companies}"
        
        # Show sample data
        puts "\n=== Sample Grant Applications ==="
        user.grant_applications.includes(:company).limit(5).each do |app|
          puts "App: #{app.title}"
          puts "  Company ID: #{app.company_id}"
          puts "  Company: #{app.company ? app.company.name : 'NIL'}"
          puts "  Company loaded?: #{app.association(:company).loaded?}"
          puts "---"
        end
        
        # Test presenter output
        puts "\n=== Presenter Output Test ==="
        begin
          search_result = GrantApplicationSearchService.new(user, {}).call
          props = GrantApplicationPresenter.index_props(
            search_result[:applications], 
            user, 
            search_result
          )
          
          puts "Presenter generated #{props[:grant_applications].count} applications"
          props[:grant_applications].first(3).each_with_index do |app, i|
            puts "App #{i+1}: #{app[:title]}"
            puts "  Company: #{app[:company] ? app[:company][:name] : 'NIL'}"
            puts "  Company ID: #{app[:company] ? app[:company][:id] : 'NIL'}"
            puts "---"
          end
        rescue => e
          puts "Error in presenter: #{e.message}"
          puts e.backtrace.first(5)
        end
      end
    end
    
    # Check companies table
    company_count = Company.count
    puts "\nTotal companies: #{company_count}"
    
    if company_count > 0
      puts "Sample companies:"
      Company.limit(5).each do |company|
        puts "  #{company.id}: #{company.name}"
      end
    end
  end
end

