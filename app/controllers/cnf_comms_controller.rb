class CnfCommsController < ApplicationController
  before_action :require_login

  def index
    log_user_action("accessed_cnf_comms")
    
    # Get search and pagination parameters
    search = params[:search]&.strip
    page = [params[:page].to_i, 1].max
    per_page = [params[:per_page].to_i, 25].max
    per_page = 25 if per_page == 0
    
    # Get R&D claims with CNF information
    all_claims = get_accessible_rnd_claims.includes(:company)
    
    # Apply search if needed
    if search.present?
      all_claims = all_claims.where(
        "rnd_claims.title LIKE ? OR rnd_claims.qualifying_activities LIKE ? OR rnd_claims.technical_challenges LIKE ? OR companies.name LIKE ?",
        "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%"
      )
    end
    
    # Calculate total count for pagination
    total_count = all_claims.count
    
    # Get paginated claims for list view
    paginated_claims = all_claims.limit(per_page).offset((page - 1) * per_page)
    
    render inertia: 'CnfComms/Index', props: {
      user: user_props,
      rnd_claims: paginated_claims.map { |claim| PropsBuilderService.rnd_claim_props(claim) },
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
      }
    }
  end

  private

  def get_accessible_rnd_claims
    if @current_user.admin?
      RndClaim.all
    elsif @current_user.employee?
      RndClaim.all # Employees can see all claims
    else
      RndClaim.where(client: @current_user) # Clients can only see their own claims
    end
  end
end
