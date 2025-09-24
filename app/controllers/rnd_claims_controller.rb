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
                        .order(Arel.sql("rnd_claims.end_date IS NULL, rnd_claims.end_date DESC, rnd_claims.created_at DESC"))
    
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
    
    # Ensure checklist items exist for this R&D claim
    ensure_checklist_items_exist
    
    render inertia: 'RndClaims/Show', props: {
      user: user_props,
      rnd_claim: PropsBuilderService.rnd_claim_props(@rnd_claim),
      projects: @rnd_claim.rnd_claim_projects.map { |project| rnd_claim_project_props(project) },
      checklist_items: @rnd_claim.rnd_checklist_items.order(:section, :title).map { |i| rnd_checklist_item_props(i) },
      can_edit: can_edit_claim?(@rnd_claim),
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
      # If CNF status changed to submitted, exempt, or not claiming, mark unsent emails as to_be_skipped
      if ['cnf_submitted', 'cnf_exempt', 'not_claiming'].include?(@rnd_claim.cnf_status)
        @rnd_claim.cnf_emails.where.not(status: 'sent').update_all(status: 'to_be_skipped')
      end
      
      # TODO: Create notification for claim updates when user-company association is established
      # if @current_user.employee? && @rnd_claim.company
      #   Notification.create_for_user(
      #     @rnd_claim.company,
      #     :claim_updated,
      #     "R&D Claim Updated",
      #     "Your R&D claim '#{@rnd_claim.title}' has been updated.",
      #     @rnd_claim
      #   )
      # end
      
      if request.xhr? || request.format.json?
        render json: { 
          success: true, 
          message: "R&D Claim '#{@rnd_claim.title}' updated successfully!",
          cnf_status: @rnd_claim.cnf_status,
          cnf_status_display: @rnd_claim.cnf_status_display
        }
      else
        redirect_to rnd_claims_path, notice: "R&D Claim '#{@rnd_claim.title}' updated successfully!"
      end
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

  def ensure_checklist_items_exist
    return if @rnd_claim.rnd_checklist_items.any?
    
    # Create default checklist items for R&D claims
    section_items = {
      'General (CSM)' => [
        'Kick off completed',
        'AML check completed',
        'Letter of authority signed'
      ],
      'Financials (FC)' => [
        'Tax account access established',
        'Org structure compiled and confirmed by client',
        'Financial information received',
        'Pipedrive updated with latest claim details'
      ],
      'Technicals (TC)' => [
        'Project list completed',
        'Technical narrative completed'
      ],
      'Finalising and filing (FC)' => [
        'Apportionments completed',
        'Calculations done',
        'Claim report compiled',
        'Signoff statements compiled',
        'Amended tax docs created (Delete if N/A)',
        'Ready for verification?',
        'Claim verified',
        'Claim finalised',
        'AIF submitted',
        'Submission pack sent to client for signoff',
        'Claim filed'
      ]
    }
    
    section_items.each do |section, items|
      items.each do |title|
        @rnd_claim.rnd_checklist_items.find_or_create_by(
          section: section,
          title: title
        )
      end
    end
  end

  def rnd_checklist_item_props(item)
    {
      id: item.id,
      section: item.section,
      title: item.title,
      due_date: item.due_date&.strftime('%Y-%m-%d'),
      checked: item.checked,
      technical_qualifier: item.technical_qualifier,
      no_technical_qualifier: item.no_technical_qualifier,
      contract_link: item.contract_link,
      review_delivered_on: item.review_delivered_on&.strftime('%Y-%m-%d'),
      invoice_sent_on: item.invoice_sent_on&.strftime('%Y-%m-%d'),
      invoice_paid_on: item.invoice_paid_on&.strftime('%Y-%m-%d'),
      resourced_subcontractor: item.resourced_subcontractor,
      delivery_folder_link: item.delivery_folder_link,
      slack_channel_name: item.slack_channel_name,
      resub_due: item.resub_due,
      eligibility_check_cost_pence: item.eligibility_check_cost_pence,
      deal_outcome: item.deal_outcome,
      completed_at: item.completed_at&.iso8601,
      notes: item.notes
    }
  end
end 