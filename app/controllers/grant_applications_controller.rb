class GrantApplicationsController < ApplicationController
  before_action :require_login
  before_action :set_grant_application, only: [:show, :edit, :update, :destroy, :change_stage]
  
  def index
    @grant_applications = @current_user.grant_applications.includes(:grant_documents, :company)
                                     .order(created_at: :desc)
    
    
    # Search functionality
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @grant_applications = @grant_applications.where(
        "title ILIKE ? OR description ILIKE ?", search_term, search_term
      )
    end
    
    # Group by stage for pipeline view
    pipeline_data = {}
    GrantApplication.stages.keys.each do |stage|
      stage_applications = @grant_applications.where(stage: stage)
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
        search: params[:search]
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
      user: user_props
    }
  end
  
  def create
    @grant_application = @current_user.grant_applications.build(grant_application_params)
    
    if @grant_application.save
      redirect_to grant_applications_path, notice: 'Grant application created successfully!'
    else
      render inertia: 'GrantApplications/New', props: {
        user: user_props,
        errors: @grant_application.errors,
        grant_application: grant_application_params
      }
    end
  end
  
  def edit
    render inertia: 'GrantApplications/Edit', props: {
      user: user_props,
      grant_application: grant_application_props(@grant_application),
      companies: Company.all.order(:name).map { |c| company_props(c) }
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
      @grant_application.update(stage: new_stage)
      render json: { 
        success: true, 
        message: "Stage updated to #{new_stage.humanize}!", 
        stage: new_stage 
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
      created_count += 1
    end

    render json: { 
      success: true, 
      created_applications: created_count,
      total_applications: GrantApplication.count,
      companies_count: companies.count
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
  end
  
  private
  
  def set_grant_application
    @grant_application = @current_user.grant_applications.find(params[:id])
  end
  
  def grant_application_params
    params.require(:grant_application).permit(:title, :description, :deadline, :stage, :company_id)
  end
  
  def grant_application_props(application)
    {
      id: application.id,
      title: application.title,
      description: application.description,
      stage: application.stage,
      stage_badge_class: view_context.grant_stage_badge_class(application.stage),
      deadline: application.deadline&.strftime("%B %d, %Y at %I:%M %p"),
      deadline_date: application.deadline&.strftime("%Y-%m-%d"),
      deadline_time: application.deadline&.strftime("%H:%M"),
      days_until_deadline: application.days_until_deadline,
      overdue: application.overdue?,
      can_edit: application.can_edit?,
      can_submit: application.can_submit?,
      created_at: application.created_at.strftime("%B %d, %Y"),
      updated_at: application.updated_at.strftime("%B %d, %Y"),
      documents_count: application.grant_documents.count,
      company: application.company ? company_props(application.company) : nil
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
      notes: item.notes,
      subbie: item.subbie,
      no_subbie: item.no_subbie,
      contract_link: item.contract_link
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
end 