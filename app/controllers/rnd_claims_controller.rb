class RndClaimsController < ApplicationController
  before_action :require_login
  before_action :require_rnd_claims_feature
  before_action :set_rnd_claim, only: [:show, :edit, :update, :destroy, :change_stage]

  def index
    log_user_action("accessed_rnd_claims")
    
    # Get search and pagination parameters
    search = params[:search]&.strip
    page = [params[:page].to_i, 1].max
    per_page = [params[:per_page].to_i, 25].max
    per_page = 25 if per_page == 0
    
    # Get all claims for pipeline data (not paginated)
    all_claims = RndClaim.includes(:company, :rnd_claim_expenditures)
                        .order(created_at: :desc)
    
    # Apply search to all claims
    if search.present?
      all_claims = all_claims.search_global(search, @current_user)
    end
    
    # Calculate total count for pagination
    total_count = all_claims.count
    
    # Get paginated claims for list view
    paginated_claims = all_claims.limit(per_page).offset((page - 1) * per_page)
    
    # Group by stage for pipeline view
    pipeline_data = {}
    stages = ['upcoming', 'readying_for_delivery', 'in_progress', 'finalised', 'filed_awaiting_hmrc', 'claim_processed', 'client_invoiced', 'paid']
    stages.each do |stage|
      stage_claims = all_claims.where(stage: stage)
      pipeline_data[stage] = {
        claims: stage_claims.map { |claim| PropsBuilderService.rnd_claim_props(claim) },
        count: stage_claims.count,
        total_value: stage_claims.sum(&:total_expenditure)
      }
    end
    
    render inertia: 'RndClaims/Index', props: {
      user: user_props,
      rnd_claims: paginated_claims.map { |claim| PropsBuilderService.rnd_claim_props(claim) },
      pipeline_data: pipeline_data,
      filters: {
        search: search,
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
        total: all_claims.count,
        total_expenditure: all_claims.sum(&:total_expenditure)
      },
      view_mode: params[:view] || 'list'
    }
  end

  def show
    unless can_view_claim?(@rnd_claim)
      redirect_to rnd_claims_path, alert: "Access denied."
      return
    end
    
    render inertia: 'RndClaims/Show', props: {
      user: user_props,
      rnd_claim: PropsBuilderService.rnd_claim_props(@rnd_claim),
      expenditures: @rnd_claim.rnd_claim_expenditures.map { |exp| rnd_claim_expenditure_props(exp) },
      projects: @rnd_claim.rnd_claim_projects.map { |project| rnd_claim_project_props(project) },
      can_edit: can_edit_claim?(@rnd_claim),
      can_add_expenditures: @current_user.employee?,
      can_add_projects: @current_user.employee?
    }
  end

  def new
    render inertia: 'RndClaims/New', props: {
      user: user_props,
      companies: get_available_companies
    }
  end

  def create
    log_user_action("creating_rnd_claim", { params: rnd_claim_params })
    
    @rnd_claim = RndClaim.new(rnd_claim_params)
    
    if @rnd_claim.save
      redirect_to rnd_claims_path, notice: "R&D Claim '#{@rnd_claim.title}' created successfully!"
    else
      render inertia: 'RndClaims/New', props: {
        user: user_props,
        companies: get_available_companies,
        errors: @rnd_claim.errors.full_messages,
        rnd_claim: { 
          title: rnd_claim_params[:title], 
          company_id: rnd_claim_params[:company_id],
          start_date: rnd_claim_params[:start_date],
          end_date: rnd_claim_params[:end_date],
          qualifying_activities: rnd_claim_params[:qualifying_activities],
          technical_challenges: rnd_claim_params[:technical_challenges]
        }
      }
    end
  end

  def edit
    unless can_edit_claim?(@rnd_claim)
      redirect_to rnd_claims_path, alert: "Access denied."
      return
    end
    
    render inertia: 'RndClaims/Edit', props: {
      user: user_props,
      rnd_claim: PropsBuilderService.rnd_claim_props(@rnd_claim),
      companies: get_available_companies
    }
  end

  def update
    unless can_edit_claim?(@rnd_claim)
      redirect_to rnd_claims_path, alert: "Access denied."
      return
    end
    
    if @rnd_claim.update(rnd_claim_params)
      # Create notification for claim updates
      if @current_user.employee? && @rnd_claim.company
        Notification.create_for_user(
          @rnd_claim.company,
          :claim_updated,
          "R&D Claim Updated",
          "Your R&D claim '#{@rnd_claim.title}' has been updated.",
          @rnd_claim
        )
      end
      
      redirect_to rnd_claims_path, notice: "R&D Claim '#{@rnd_claim.title}' updated successfully!"
    else
      render inertia: 'RndClaims/Edit', props: {
        user: user_props,
        rnd_claim: PropsBuilderService.rnd_claim_props(@rnd_claim),
        companies: get_available_companies,
        errors: @rnd_claim.errors.full_messages
      }
    end
  end

  def destroy
    unless can_edit_claim?(@rnd_claim)
      redirect_to rnd_claims_path, alert: "Access denied."
      return
    end
    
    title = @rnd_claim.title
    if @rnd_claim.destroy
      redirect_to rnd_claims_path, notice: "R&D Claim '#{title}' deleted successfully!"
    else
      redirect_to rnd_claims_path, alert: "Failed to delete R&D Claim '#{title}'."
    end
  end

  def change_stage
    unless can_edit_claim?(@rnd_claim)
      render json: { success: false, message: "Access denied." }, status: :forbidden
      return
    end
    
    new_stage = params[:stage]
    
    if @rnd_claim.update(stage: new_stage)
      render json: { 
        success: true, 
        message: "Stage updated to #{new_stage.humanize} successfully!",
        stage: new_stage
      }
    else
      render json: { 
        success: false, 
        message: "Failed to update stage: #{@rnd_claim.errors.full_messages.join(', ')}" 
      }, status: :unprocessable_entity
    end
  end

    private
  
  def require_rnd_claims_feature
    require_feature('rnd_claims')
  end
  
  def set_rnd_claim
    @rnd_claim = RndClaim.find(params[:id])
  end

  def rnd_claim_params
    permitted_params = [:title, :start_date, :end_date, :qualifying_activities, :technical_challenges, :company_id, :stage, :cnf_status, :cnf_deadline]
    params.require(:rnd_claim).permit(*permitted_params)
  end



  def can_view_claim?(claim)
    @current_user.admin? || @current_user.employee?
  end

  def can_edit_claim?(claim)
    @current_user.admin? || @current_user.employee?
  end

  def get_available_companies
    Company.order(:name)
  end



  def calculate_stats(claims)
    {
      total: claims.count,
      total_expenditure: claims.sum(&:total_expenditure)
    }
  end

  def rnd_claim_project_props(project)
    {
      id: project.id,
      name: project.name,
      qualification_status: project.qualification_status,
      narrative_status: project.narrative_status,
      qualification_status_display: project.qualification_status_display,
      narrative_status_display: project.narrative_status_display,
      created_at: project.created_at.strftime('%d/%m/%Y %H:%M'),
      updated_at: project.updated_at.strftime('%d/%m/%Y %H:%M')
    }
  end
end 