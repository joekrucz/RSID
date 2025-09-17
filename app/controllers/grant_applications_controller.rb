class GrantApplicationsController < ApplicationController
  before_action :require_login
  before_action :set_grant_application, only: [:show, :edit, :update, :destroy, :change_stage]
  skip_before_action :verify_authenticity_token, only: [:fix_company_links, :add_massive_demo_data]
  
  def index
    @grant_applications = @current_user.grant_applications.includes(:grant_documents, :company)
                                     .order(created_at: :desc)
    
    # Search functionality
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      if ActiveRecord::Base.connection.adapter_name.downcase == 'postgresql'
      @grant_applications = @grant_applications.where(
        "title ILIKE ? OR description ILIKE ?", search_term, search_term
      )
      else
        # SQLite3 and other databases
        search_term_upcase = "%#{params[:search].upcase}%"
        @grant_applications = @grant_applications.where(
          "UPPER(title) LIKE ? OR UPPER(description) LIKE ?", search_term_upcase, search_term_upcase
        )
      end
    end
    
    # Pagination
    per_page = params[:per_page].present? ? params[:per_page].to_i : 25
    per_page = [25, 50, 100].include?(per_page) ? per_page : 25 # Validate per_page
    page = params[:page].present? ? params[:page].to_i : 1
    
    # Use limit and offset for pagination (fallback if Kaminari isn't working)
    offset = (page - 1) * per_page
    @grant_applications = @grant_applications.limit(per_page).offset(offset)
    
    # Get total count for pagination info
    total_count = @current_user.grant_applications.count
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      if ActiveRecord::Base.connection.adapter_name.downcase == 'postgresql'
        total_count = @current_user.grant_applications.where(
          "title ILIKE ? OR description ILIKE ?", search_term, search_term
        ).count
      else
        # SQLite3 and other databases
        search_term_upcase = "%#{params[:search].upcase}%"
        total_count = @current_user.grant_applications.where(
          "UPPER(title) LIKE ? OR UPPER(description) LIKE ?", search_term_upcase, search_term_upcase
        ).count
      end
    end
    
    # Group by stage for pipeline view (using all applications, not paginated)
    all_applications = @current_user.grant_applications.includes(:grant_documents, :company)
                                   .order(created_at: :desc)
    
    # Apply search to pipeline data too
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      if ActiveRecord::Base.connection.adapter_name.downcase == 'postgresql'
        all_applications = all_applications.where(
          "title ILIKE ? OR description ILIKE ?", search_term, search_term
        )
      else
        # SQLite3 and other databases
        search_term_upcase = "%#{params[:search].upcase}%"
        all_applications = all_applications.where(
          "UPPER(title) LIKE ? OR UPPER(description) LIKE ?", search_term_upcase, search_term_upcase
        )
      end
    end
    
    pipeline_data = {}
    GrantApplication.stages.keys.each do |stage|
      stage_applications = all_applications.where(stage: stage)
      pipeline_data[stage] = {
        applications: stage_applications.map { |app| grant_application_props(app) },
        count: stage_applications.count,
        total_value: 0 # We can add value calculation later if needed
      }
    end
    
    render inertia: 'GrantApplications/Index', props: {
      user: user_props,
      grant_applications: @grant_applications.map { |app| grant_application_props(app) },
      pipeline_data: pipeline_data,
      filters: {
        search: params[:search],
        per_page: per_page
      },
      pagination: {
        current_page: page,
        total_pages: (total_count.to_f / per_page).ceil,
        per_page: per_page,
        total_count: total_count,
        has_next_page: (page * per_page) < total_count,
        has_prev_page: page > 1
      },
      stats: {
        total: @current_user.grant_applications.count,
        overdue: @current_user.grant_applications.overdue.count
      },
      view_mode: params[:view] || 'list'
    }
  end
  
  def show
    render inertia: 'GrantApplications/Show', props: {
      user: user_props,
      grant_application: grant_application_props(@grant_application),
      checklist_items: @grant_application.grant_checklist_items.order(:section, :title).map { |i| checklist_item_props(i) },
      documents: @grant_application.grant_documents.map { |doc| document_props(doc) }
    }
  end
  
  def new
    render inertia: 'GrantApplications/New', props: {
      user: user_props,
      companies: Company.all.order(:name).map { |c| company_props(c) },
      competitions: GrantCompetition.all.order(:deadline).map { |c| competition_props(c) }
    }
  end
  
  def create
    @grant_application = @current_user.grant_applications.build(grant_application_params)
    
    if @grant_application.save
      redirect_to grant_applications_path, notice: 'Grant application created successfully!'
    else
      render inertia: 'GrantApplications/New', props: {
        user: user_props,
        companies: Company.all.order(:name).map { |c| company_props(c) },
        competitions: GrantCompetition.all.order(:deadline).map { |c| competition_props(c) },
        errors: @grant_application.errors,
        grant_application: grant_application_params
      }
    end
  end
  
  def edit
    render inertia: 'GrantApplications/Edit', props: {
      user: user_props,
      grant_application: grant_application_props(@grant_application),
      companies: Company.all.order(:name).map { |c| company_props(c) },
      competitions: GrantCompetition.all.order(:deadline).map { |c| competition_props(c) }
    }
  end
  
  def update
    if @grant_application.update(grant_application_params)
      redirect_to grant_applications_path, notice: 'Grant application updated successfully!'
    else
      render inertia: 'GrantApplications/Edit', props: {
        user: user_props,
        grant_application: grant_application_props(@grant_application),
        errors: @grant_application.errors.full_messages
      }
    end
  end
  
  def destroy
    @grant_application.destroy
    redirect_to grant_applications_path, notice: 'Grant application deleted successfully!'
  end
  
  

  def change_stage
    new_stage = params[:stage]
    if GrantApplication.stages.key?(new_stage)
      @grant_application.update(stage: new_stage, manual_stage_override: true)
      render json: { 
        success: true, 
        message: "Stage updated to #{new_stage.humanize}!", 
        stage: new_stage,
        manual_override: true,
        conflict_warning: @grant_application.stage_conflict_message,
        conflict_details: @grant_application.stage_conflict_details
      }
    else
      render json: { 
        success: false, 
        message: 'Invalid stage.' 
      }, status: :unprocessable_entity
    end
  end
  
  def link_companies
    # This is a temporary endpoint to link companies to grant applications
    companies = Company.all
    if companies.empty?
      render json: { error: "No companies found" }
      return
    end

    unlinked_applications = GrantApplication.where(company_id: nil)
    linked_count = 0
    
    unlinked_applications.each do |app|
      app.update!(company: companies.sample)
      linked_count += 1
    end

    render json: { 
      success: true, 
      linked_count: linked_count,
      total_applications: GrantApplication.count,
      companies_count: companies.count
    }
  end

  def add_demo_data
    # Endpoint to add more demo data
    user = User.first
    companies = Company.all
    
    if companies.empty?
      render json: { error: "No companies found. Run seeds first." }
      return
    end

    # Add more grant applications
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
      # Seed checklist items to match stage
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
        (section_items[section] || []).each do |title|
          application.grant_checklist_items.create!(section: section, title: title, checked: idx <= current_idx)
        end
      end
      created_count += 1
    end

    render json: { 
      success: true, 
      created_applications: created_count,
      total_applications: GrantApplication.count,
      companies_count: companies.count
    }
  end

  def add_massive_demo_data
    # Endpoint to add 50 more companies and 50 more applications
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
      # Link each application to a corresponding newly created company
      company = created_companies[index % created_companies.length]
      
      application = GrantApplication.create!(
        user: user,
        title: title,
        description: "Advanced research and development project for #{title}",
        deadline: deadline,
        stage: GrantApplication.stages.keys.sample,
        company: company
      )
      # Seed checklist items to match stage
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
          application.grant_checklist_items.create!(section: section, title: item_title, checked: idx <= current_idx)
        end
      end
      created_applications << application
    end

    render json: { 
      success: true, 
      created_companies: created_companies.count,
      created_applications: created_applications.count,
      total_companies: Company.count,
      total_applications: GrantApplication.count
    }
  end

  def debug_data
    # Debug endpoint to see what data is being sent to frontend
    applications = @current_user.grant_applications.includes(:company, :grant_documents).order(created_at: :desc)
    
    debug_info = {
      user_id: @current_user.id,
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
      # Additional debug info
      all_companies: Company.all.map { |c| { id: c.id, name: c.name } },
      applications_with_company_id: applications.select { |app| app.company_id.present? }.count,
      applications_without_company_id: applications.select { |app| app.company_id.nil? }.count
    }
    
    render json: debug_info
  end

  def fix_company_links
    # Fix endpoint to link all applications to companies
    companies = Company.all
    if companies.empty?
      render json: { error: "No companies found" }
      return
    end

    # Get all applications for this user that don't have a company
    unlinked_applications = @current_user.grant_applications.where(company_id: nil)
    linked_count = 0
    
    begin
      unlinked_applications.each do |app|
        app.update!(company: companies.sample)
        linked_count += 1
      end

      render json: { 
        success: true, 
        linked_count: linked_count,
        total_applications: @current_user.grant_applications.count,
        companies_count: companies.count
      }
    rescue => e
      render json: { 
        success: false, 
        error: e.message,
        linked_count: linked_count
      }
    end
  end
  
  private
  
  def set_grant_application
    @grant_application = @current_user.grant_applications.find(params[:id])
  end
  
  def grant_application_params
    params.require(:grant_application).permit(:title, :description, :stage, :company_id, :grant_competition_id)
  end
  
  def grant_application_props(application)
    {
      id: application.id,
      title: application.title,
      description: application.description,
      stage: application.stage,
      stage_badge_class: view_context.grant_stage_badge_class(application.stage),
      days_until_deadline: application.days_until_deadline,
      overdue: application.overdue?,
      can_edit: application.can_edit?,
      can_submit: application.can_submit?,
      created_at: application.created_at.strftime("%B %d, %Y"),
      updated_at: application.updated_at.strftime("%B %d, %Y"),
      documents_count: application.grant_documents.count,
      company: application.company ? company_props(application.company) : nil,
      grant_competition: application.grant_competition ? competition_props(application.grant_competition) : nil,
      manual_stage_override: application.manual_stage_override?,
      stage_conflict: application.stage_conflict?,
      stage_conflict_message: application.stage_conflict_message,
      stage_conflict_details: application.stage_conflict_details,
      automatic_stage: application.automatic_stage
    }
  end
  
  def document_props(document)
    {
      id: document.id,
      name: document.name,
      file_type: document.file_type,
      file_size: format_file_size(document.file_size),
      icon_class: document.icon_class,
      created_at: document.created_at.strftime("%B %d, %Y")
    }
  end

  def checklist_item_props(item)
    {
      id: item.id,
      section: item.section,
      title: item.title,
      due_date: item.due_date&.strftime('%Y-%m-%d'),
      checked: item.checked,
      subbie: item.subbie,
      no_subbie: item.no_subbie,
      contract_link: item.contract_link,
      review_delivered_on: item.review_delivered_on&.strftime('%Y-%m-%d'),
      deal_outcome: item.deal_outcome,
      notes: item.notes
    }
  end
  
  def company_props(company)
    {
      id: company.id,
      name: company.name,
      website: company.website,
      notes: company.notes
    }
  end

  def competition_props(competition)
    {
      id: competition.id,
      grant_name: competition.grant_name,
      deadline: competition.deadline,
      funding_body: competition.funding_body,
      competition_link: competition.competition_link,
      status: competition.status,
      upcoming: competition.upcoming?,
      past: competition.past?,
      days_until_deadline: competition.days_until_deadline
    }
  end
end 