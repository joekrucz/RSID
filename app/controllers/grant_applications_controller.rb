class GrantApplicationsController < ApplicationController
  before_action :require_login
  before_action :set_grant_application, only: [:show, :edit, :update, :destroy, :change_status, :change_stage]
  
  def index
    @grant_applications = @current_user.grant_applications.includes(:grant_documents, :company)
                                     .order(created_at: :desc)
    
    # Filter by status if provided
    if params[:status].present?
      @grant_applications = @grant_applications.by_status(params[:status])
    end
    
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
        status: params[:status],
        search: params[:search]
      },
      stats: {
        total: @current_user.grant_applications.count,
        draft: @current_user.grant_applications.by_status('draft').count,
        submitted: @current_user.grant_applications.by_status('submitted').count,
        under_review: @current_user.grant_applications.by_status('under_review').count,
        approved: @current_user.grant_applications.by_status('approved').count,
        rejected: @current_user.grant_applications.by_status('rejected').count,
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
  
  
  def change_status
    new_status = params[:status]
    if GrantApplication.statuses.key?(new_status)
      @grant_application.update(status: new_status)
      redirect_to grant_applications_path, notice: "Status updated to #{new_status.humanize}!"
    else
      redirect_to grant_applications_path, alert: 'Invalid status.'
    end
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
  
  private
  
  def set_grant_application
    @grant_application = @current_user.grant_applications.find(params[:id])
  end
  
  def grant_application_params
    params.require(:grant_application).permit(:title, :description, :deadline, :status, :stage, :company_id)
  end
  
  def grant_application_props(application)
    {
      id: application.id,
      title: application.title,
      description: application.description,
      status: application.status,
      status_color: grant_application_status_color(application.status),
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