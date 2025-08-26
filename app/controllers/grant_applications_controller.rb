class GrantApplicationsController < ApplicationController
  before_action :require_login
  before_action :set_grant_application, only: [:show, :edit, :update, :destroy, :submit, :change_status]
  
  def index
    @grant_applications = @current_user.grant_applications.includes(:grant_documents)
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
    
    render inertia: 'GrantApplications/Index', props: {
      user: user_props,
      grant_applications: @grant_applications.map { |app| grant_application_props(app) },
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
      }
    }
  end
  
  def show
    render inertia: 'GrantApplications/Show', props: {
      user: user_props,
      grant_application: grant_application_props(@grant_application),
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
      grant_application: grant_application_props(@grant_application)
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
  
  def submit
    if @grant_application.can_submit?
      @grant_application.update(status: :submitted)
      redirect_to grant_applications_path, notice: 'Grant application submitted successfully!'
    else
      redirect_to grant_applications_path, alert: 'Cannot submit this application.'
    end
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
  
  private
  
  def set_grant_application
    @grant_application = @current_user.grant_applications.find(params[:id])
  end
  
  def grant_application_params
    params.require(:grant_application).permit(:title, :description, :deadline, :status)
  end
  
  def grant_application_props(application)
    {
      id: application.id,
      title: application.title,
      description: application.description,
      status: application.status,
      status_color: application.status_color,
      deadline: application.deadline&.strftime("%B %d, %Y at %I:%M %p"),
      deadline_date: application.deadline&.strftime("%Y-%m-%d"),
      deadline_time: application.deadline&.strftime("%H:%M"),
      days_until_deadline: application.days_until_deadline,
      overdue: application.overdue?,
      can_edit: application.can_edit?,
      can_submit: application.can_submit?,
      created_at: application.created_at.strftime("%B %d, %Y"),
      updated_at: application.updated_at.strftime("%B %d, %Y"),
      documents_count: application.grant_documents.count
    }
  end
  
  def document_props(document)
    {
      id: document.id,
      name: document.name,
      file_type: document.file_type,
      file_size: document.file_size_formatted,
      icon_class: document.icon_class,
      created_at: document.created_at.strftime("%B %d, %Y")
    }
  end
end 