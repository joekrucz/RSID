# DemoDataService
# 
# Handles demo data creation and management for development purposes.
# Extracted from GrantApplicationsController to follow Single Responsibility Principle.
class DemoDataService
  def link_companies
    companies = Company.all
    if companies.empty?
      return { error: "No companies found" }
    end

    unlinked_applications = GrantApplication.where(company_id: nil)
    linked_count = 0
    
    unlinked_applications.each do |app|
      app.update!(company: companies.sample)
      linked_count += 1
    end

    { 
      success: true, 
      linked_count: linked_count,
      total_applications: GrantApplication.count,
      companies_count: companies.count
    }
  end

  def add_demo_data
    user = User.first
    companies = Company.all
    
    if companies.empty?
      return { error: "No companies found. Run seeds first." }
    end

    new_applications = [
      { title: 'Advanced AI Research', description: 'Next-generation AI algorithms for complex problems', days_from_now: 15 },
      { title: 'Sustainable Energy Grid', description: 'Smart grid technology for renewable energy', days_from_now: 22 },
      { title: 'Biotech Innovation Lab', description: 'Cutting-edge biotechnology research facility', days_from_now: 30 },
      { title: 'Cybersecurity Fortress', description: 'Advanced threat detection and prevention systems', days_from_now: 18 },
      { title: 'Space Exploration Tech', description: 'Technology for deep space missions', days_from_now: 45 }
    ]

    created_count = 0
    new_applications.each do |app_data|
      deadline = Time.current + app_data[:days_from_now].days
      application = GrantApplication.create!(
        user: user,
        title: app_data[:title],
        description: app_data[:description],
        deadline: deadline,
        stage: GrantApplication.stages.keys.sample,
        company: companies.sample
      )
      create_checklist_items(application)
      created_count += 1
    end

    { 
      success: true, 
      created_applications: created_count,
      total_applications: GrantApplication.count,
      companies_count: companies.count
    }
  end

  def add_massive_demo_data
    user = User.first
    
    # Create 50 new companies
    company_names = [
      'Quantum Computing Corp', 'Neural Networks Inc', 'Blockchain Solutions Ltd', 'Robotics Dynamics', 'Green Energy Systems',
      'Data Analytics Pro', 'Cloud Infrastructure Co', 'Mobile App Innovations', 'AI Healthcare Solutions', 'FinTech Revolution',
      'Space Technology Ltd', 'Biotech Research Group', 'Cyber Security Experts', 'IoT Development Co', 'Machine Learning Labs',
      'Virtual Reality Studios', 'Augmented Reality Tech', 'Edge Computing Solutions', '5G Network Systems', 'Smart City Technologies',
      'Autonomous Vehicles Inc', 'Drone Technology Corp', 'Renewable Energy Co', 'Carbon Capture Systems', 'Water Purification Tech',
      'Food Security Solutions', 'Agricultural Automation', 'Precision Medicine Labs', 'Gene Therapy Research', 'Drug Discovery Systems',
      'Wearable Technology Co', 'Smart Home Solutions', 'Digital Twin Systems', 'Predictive Analytics Inc', 'Real-time Processing Co',
      'Distributed Computing Ltd', 'Microservices Architecture', 'API Gateway Solutions', 'Database Optimization Co', 'Cache Management Systems',
      'Load Balancing Tech', 'Container Orchestration', 'Serverless Computing Co', 'Event Streaming Systems', 'Message Queue Solutions',
      'Search Engine Optimization', 'Content Delivery Networks', 'CDN Acceleration Co', 'Web Performance Labs', 'User Experience Design'
    ]

    created_companies = []
    company_names.each do |name|
      company = Company.create!(
        name: name,
        website: "https://#{name.downcase.gsub(/\s+/, '')}.com",
        notes: "Demo company for #{name}"
      )
      created_companies << company
    end

    # Create 50 new grant applications linked to the newly created companies
    application_titles = [
      'Quantum Algorithm Development', 'Neural Network Optimization', 'Blockchain Security Protocol', 'Robotic Process Automation', 'Green Energy Storage',
      'Big Data Analytics Platform', 'Cloud Migration Strategy', 'Mobile Payment System', 'AI Diagnostic Tools', 'Digital Banking Solutions',
      'Satellite Communication Tech', 'Gene Editing Research', 'Network Security Framework', 'Smart Sensor Networks', 'Deep Learning Models',
      'VR Training Simulations', 'AR Navigation Systems', 'Edge AI Processing', '5G Infrastructure', 'Smart Traffic Management',
      'Self-Driving Car Software', 'Drone Delivery Network', 'Solar Panel Efficiency', 'Carbon Neutral Technology', 'Water Treatment Systems',
      'Vertical Farming Solutions', 'Precision Agriculture', 'Personalized Medicine', 'Gene Therapy Delivery', 'Drug Testing Automation',
      'Health Monitoring Devices', 'Smart Building Controls', 'Digital Twin Platform', 'Predictive Maintenance', 'Real-time Data Processing',
      'Distributed Database Systems', 'Microservices Architecture', 'API Management Platform', 'Database Performance Tuning', 'Intelligent Caching',
      'Load Distribution Algorithms', 'Container Management', 'Serverless Functions', 'Event Processing Engine', 'Message Queue Optimization',
      'Search Algorithm Enhancement', 'Content Distribution', 'CDN Performance', 'Web Speed Optimization', 'UX Research Platform'
    ]

    created_applications = []
    application_titles.each_with_index do |title, index|
      deadline = Time.current + rand(1..90).days
      company = created_companies[index % created_companies.length]
      
      application = GrantApplication.create!(
        user: user,
        title: title,
        description: "Advanced research and development project for #{title}",
        deadline: deadline,
        stage: GrantApplication.stages.keys.sample,
        company: company
      )
      create_checklist_items(application)
      created_applications << application
    end

    { 
      success: true, 
      created_companies: created_companies.count,
      created_applications: created_applications.count,
      total_companies: Company.count,
      total_applications: GrantApplication.count
    }
  end

  def debug_data(user)
    applications = user.grant_applications.includes(:company, :grant_documents).order(created_at: :desc)
    
    {
      user_id: user.id,
      total_applications: applications.count,
      applications: applications.map do |app|
        {
          id: app.id,
          title: app.title,
          company: app.company ? {
            id: app.company.id,
            name: app.company.name
          } : nil,
          company_id: app.company_id,
          raw_company_id: app.read_attribute(:company_id)
        }
      end,
      all_companies: Company.all.map { |c| { id: c.id, name: c.name } },
      applications_with_company_id: applications.select { |app| app.company_id.present? }.count,
      applications_without_company_id: applications.select { |app| app.company_id.nil? }.count
    }
  end

  def fix_company_links(user)
    companies = Company.all
    if companies.empty?
      return { error: "No companies found" }
    end

    unlinked_applications = user.grant_applications.where(company_id: nil)
    linked_count = 0
    
    begin
      unlinked_applications.each do |app|
        app.update!(company: companies.sample)
        linked_count += 1
      end

      { 
        success: true, 
        linked_count: linked_count,
        total_applications: user.grant_applications.count,
        companies_count: companies.count
      }
    rescue => e
      { 
        success: false, 
        error: e.message,
        linked_count: linked_count
      }
    end
  end

  private

  def create_checklist_items(application)
    section_order = [
      'Client Acquisition/Project Qualification',
      'Client Invoiced',
      'Invoice Paid',
      'Preparing for Kick Off/AML/Resourcing',
      'Kicked Off/In Progress',
      'Submitted',
      'Awaiting Funding Decision',
      'Application Successful/Not Successful',
      'Resub Due',
      'Success Fee Invoiced',
      'Success Fee Paid'
    ]
    
    section_items = {
      'Client Acquisition/Project Qualification' => [
        'Project Qualification', 'Proposal Presented', 'Agreement Sent', 'New Project Handover Sent To Delivery', 'Deal marked as "won" / "lost"'
      ],
      'Client Invoiced' => ['Invoice Sent'],
      'Invoice Paid' => ['Payment Received'],
      'Preparing for Kick Off/AML/Resourcing' => ['AML Checks Completed', 'Project Resourced', 'Project Set Up - Slack Channel, Delivery Folders, Etc.'],
      'Kicked Off/In Progress' => ['Kick Off Call Confirmed', 'Timeline Confirmed and Accepted by Client', 'Drafting', 'Reviews Confirmed', 'Eligibility Checks Completed'],
      'Submitted' => ['Application Submitted'],
      'Awaiting Funding Decision' => ['Completed'],
      'Application Successful/Not Successful' => ['Completed'],
      'Resub Due' => ['Completed'],
      'Success Fee Invoiced' => ['Completed'],
      'Success Fee Paid' => ['Completed']
    }
    
    current_idx = GrantApplication.stages[application.stage]
    section_order.each_with_index do |section, idx|
      (section_items[section] || []).each do |item_title|
        application.grant_checklist_items.create!(
          section: section, 
          title: item_title, 
          checked: idx <= current_idx
        )
      end
    end
  end
end
