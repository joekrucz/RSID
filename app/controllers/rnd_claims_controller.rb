class RndClaimsController < ApplicationController
  before_action :require_login
  before_action :require_rnd_claims_feature
  before_action :set_rnd_claim, only: [:show, :edit, :update, :destroy]

  def index
    log_user_action("accessed_rnd_claims")
    
    # Get search and filter parameters
    search = params[:search]&.strip
    sort_by = params[:sort_by] || 'created_at'
    sort_order = params[:sort_order] || 'desc'
    
    claims = RndClaim.filtered_and_sorted(@current_user, search: search, sort_by: sort_by, sort_order: sort_order)
    
    render inertia: 'RndClaims/Index', props: {
      user: user_props,
      rnd_claims: claims.map { |claim| PropsBuilderService.rnd_claim_props(claim) },
      search: search,
      sort_by: sort_by,
      sort_order: sort_order,
      can_create_claims: @current_user.employee? || @current_user.admin?,
      can_manage_claims: @current_user.employee? || @current_user.admin?,
      stats: calculate_stats(claims),
      companies: get_available_companies
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
      can_edit: can_edit_claim?(@rnd_claim),
      can_add_expenditures: @current_user.employee?
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
          description: rnd_claim_params[:description],
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
      if @current_user.employee?
        Notification.create_for_user(
          @rnd_claim.client,
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
        clients: get_available_clients,
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

    private
  
  def require_rnd_claims_feature
    require_feature('rnd_claims')
  end
  
  def set_rnd_claim
    @rnd_claim = RndClaim.find(params[:id])
  end

  def rnd_claim_params
    permitted_params = [:title, :description, :start_date, :end_date, :qualifying_activities, :technical_challenges, :company_id]
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
end 