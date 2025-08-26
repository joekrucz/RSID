class RndProjectsController < ApplicationController
  before_action :require_login
  before_action :require_rnd_projects_feature
  before_action :set_rnd_project, only: [:show, :edit, :update, :destroy]

  def index
    Rails.logger.info "R&D Projects accessed by user: #{@current_user.name} (Role: #{@current_user.role})"
    
    # Get search and filter parameters
    search = params[:search]&.strip
    status_filter = params[:status_filter]&.strip
    client_filter = params[:client_filter]&.strip
    sort_by = params[:sort_by] || 'created_at'
    sort_order = params[:sort_order] || 'desc'
    
    projects = RndProject.filtered_and_sorted(@current_user, search: search, status_filter: status_filter, client_filter: client_filter, sort_by: sort_by, sort_order: sort_order)
    
    render inertia: 'RndProjects/Index', props: {
      user: user_props,
      rnd_projects: projects.map { |project| rnd_project_props(project) },
      search: search,
      status_filter: status_filter,
      client_filter: client_filter,
      sort_by: sort_by,
      sort_order: sort_order,
      can_create_projects: @current_user.employee? || @current_user.client?,
      can_manage_projects: @current_user.employee? || @current_user.client?,
      stats: calculate_stats(projects),
      clients: get_available_clients
    }
  end

  def show
    unless can_view_project?(@rnd_project)
      redirect_to rnd_projects_path, alert: "Access denied."
      return
    end
    
    render inertia: 'RndProjects/Show', props: {
      user: user_props,
      rnd_project: rnd_project_props(@rnd_project),
      expenditures: @rnd_project.rnd_expenditures.map { |exp| rnd_expenditure_props(exp) },
      can_edit: can_edit_project?(@rnd_project),
      can_add_expenditures: @current_user.employee?
    }
  end

  def new
    render inertia: 'RndProjects/New', props: {
      user: user_props,
      clients: get_available_clients
    }
  end

  def create
    Rails.logger.info "Creating R&D project with params: #{rnd_project_params}"
    Rails.logger.info "Current user role: #{@current_user.role}"
    Rails.logger.info "Available clients: #{get_available_clients.count}"
    
    @rnd_project = RndProject.new(rnd_project_params)
    @rnd_project.status = :draft
    
    # If current user is a client, automatically set them as the client
    if @current_user.client?
      @rnd_project.client_id = @current_user.id
      Rails.logger.info "Setting client_id to current user: #{@current_user.id}"
    end
    
    Rails.logger.info "R&D project client_id before save: #{@rnd_project.client_id}"
    Rails.logger.info "R&D project valid? #{@rnd_project.valid?}"
    Rails.logger.info "R&D project errors: #{@rnd_project.errors.full_messages}" unless @rnd_project.valid?
    
    if @rnd_project.save
      redirect_to rnd_projects_path, notice: "R&D Project '#{@rnd_project.title}' created successfully!"
    else
      render inertia: 'RndProjects/New', props: {
        user: user_props,
        clients: get_available_clients,
        errors: @rnd_project.errors.full_messages,
        rnd_project: { 
          title: rnd_project_params[:title], 
          description: rnd_project_params[:description],
          client_id: rnd_project_params[:client_id],
          start_date: rnd_project_params[:start_date],
          end_date: rnd_project_params[:end_date],
          qualifying_activities: rnd_project_params[:qualifying_activities],
          technical_challenges: rnd_project_params[:technical_challenges]
        }
      }
    end
  end

  def edit
    unless can_edit_project?(@rnd_project)
      redirect_to rnd_projects_path, alert: "Access denied."
      return
    end
    
    render inertia: 'RndProjects/Edit', props: {
      user: user_props,
      rnd_project: rnd_project_props(@rnd_project),
      clients: get_available_clients
    }
  end

  def update
    unless can_edit_project?(@rnd_project)
      redirect_to rnd_projects_path, alert: "Access denied."
      return
    end
    
    if @rnd_project.update(rnd_project_params)
      redirect_to rnd_projects_path, notice: "R&D Project '#{@rnd_project.title}' updated successfully!"
    else
      render inertia: 'RndProjects/Edit', props: {
        user: user_props,
        rnd_project: rnd_project_props(@rnd_project),
        clients: get_available_clients,
        errors: @rnd_project.errors.full_messages
      }
    end
  end

  def destroy
    unless can_edit_project?(@rnd_project)
      redirect_to rnd_projects_path, alert: "Access denied."
      return
    end
    
    title = @rnd_project.title
    if @rnd_project.destroy
      redirect_to rnd_projects_path, notice: "R&D Project '#{title}' deleted successfully!"
    else
      redirect_to rnd_projects_path, alert: "Failed to delete R&D Project '#{title}'."
    end
  end

    private
  
  def require_rnd_projects_feature
    require_feature('rnd_projects')
  end
  
  def set_rnd_project
    @rnd_project = RndProject.find(params[:id])
  end

  def rnd_project_params
    permitted_params = [:title, :description, :start_date, :end_date, :status, :qualifying_activities, :technical_challenges]
    permitted_params << :client_id if @current_user.employee? || @current_user.admin? || @current_user.client?
    params.require(:rnd_project).permit(*permitted_params)
  end



  def can_view_project?(project)
    @current_user.admin? || 
    @current_user.employee? || 
    project.client_id == @current_user.id
  end

  def can_edit_project?(project)
    @current_user.admin? || 
    @current_user.employee? ||
    (@current_user.client? && project.client_id == @current_user.id)
  end

  def get_available_clients
    if @current_user.admin?
      User.clients.ordered_by_name
    elsif @current_user.employee?
      User.clients.ordered_by_name
    else
      # Clients can only see themselves
      User.where(id: @current_user.id).ordered_by_name
    end
  end

  def rnd_project_props(project)
    {
      id: project.id,
      title: project.title,
      description: project.description,
      client: {
        id: project.client.id,
        name: project.client.name,
        email: project.client.email
      },
      start_date: project.start_date&.strftime("%Y-%m-%d"),
      end_date: project.end_date&.strftime("%Y-%m-%d"),
      status: project.status,
      qualifying_activities: project.qualifying_activities,
      technical_challenges: project.technical_challenges,
      total_expenditure: project.total_expenditure,
      expenditure_by_type: project.expenditure_by_type,
      duration_days: project.duration_days,
      is_active: project.is_active?,
      can_be_claimed: project.can_be_claimed?,
      created_at: project.created_at.strftime("%B %d, %Y"),
      updated_at: project.updated_at.strftime("%B %d, %Y")
    }
  end

  def rnd_expenditure_props(expenditure)
    {
      id: expenditure.id,
      expenditure_type: expenditure.expenditure_type,
      amount: expenditure.amount,
      description: expenditure.description,
      date: expenditure.date&.strftime("%Y-%m-%d"),
      qualifying_amount: expenditure.qualifying_amount,
      is_qualifying: expenditure.is_qualifying?,
      formatted_amount: expenditure.formatted_amount,
      formatted_qualifying_amount: expenditure.formatted_qualifying_amount,
      created_at: expenditure.created_at.strftime("%B %d, %Y")
    }
  end

  def calculate_stats(projects)
    {
      total: projects.count,
      draft: projects.where(status: 'draft').count,
      active: projects.where(status: 'active').count,
      completed: projects.where(status: 'completed').count,
      ready_for_claim: projects.where(status: 'ready_for_claim').count,
      total_expenditure: projects.sum(&:total_expenditure)
    }
  end
end 