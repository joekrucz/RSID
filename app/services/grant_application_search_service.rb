# GrantApplicationSearchService
# 
# Handles search, pagination, and pipeline data for grant applications.
# Extracted from GrantApplicationsController to follow Single Responsibility Principle.
class GrantApplicationSearchService
  def initialize(user, params)
    @user = user
    @params = params
  end

  def call
    applications = @user.grant_applications.includes(:grant_documents, :company)
    applications = apply_search(applications) if @params[:search].present?
    applications = apply_pagination(applications)
    
    {
      applications: applications,
      total_count: total_count,
      pipeline_data: build_pipeline_data,
      search: @params[:search],
      per_page: validate_per_page(@params[:per_page]),
      view_mode: @params[:view] || 'list'
    }
  end

  private

  def apply_search(applications)
    sanitized_search = SanitizationService.sanitize_search_term(@params[:search])
    return applications if sanitized_search.blank?
    
    search_term = "%#{sanitized_search}%"
    if ActiveRecord::Base.connection.adapter_name.downcase == 'postgresql'
      applications.where("title ILIKE ? OR description ILIKE ?", search_term, search_term)
    else
      search_term_upcase = "%#{sanitized_search.upcase}%"
      applications.where("UPPER(title) LIKE ? OR UPPER(description) LIKE ?", search_term_upcase, search_term_upcase)
    end
  end

  def apply_pagination(applications)
    per_page = validate_per_page(@params[:per_page])
    page = @params[:page].to_i.positive? ? @params[:page].to_i : 1
    
    applications.page(page).per(per_page)
  end

  def validate_per_page(per_page_param)
    per_page = per_page_param.to_i
    [25, 50, 100].include?(per_page) ? per_page : 25
  end

  def total_count
    base_query = @user.grant_applications.includes(:grant_documents, :company)
    
    if @params[:search].present?
      sanitized_search = SanitizationService.sanitize_search_term(@params[:search])
      if sanitized_search.present?
        search_term = "%#{sanitized_search}%"
        if ActiveRecord::Base.connection.adapter_name.downcase == 'postgresql'
          base_query.where("title ILIKE ? OR description ILIKE ?", search_term, search_term).count
        else
          search_term_upcase = "%#{sanitized_search.upcase}%"
          base_query.where("UPPER(title) LIKE ? OR UPPER(description) LIKE ?", search_term_upcase, search_term_upcase).count
        end
      else
        base_query.count
      end
    else
      base_query.count
    end
  end

  def build_pipeline_data
    all_applications = @user.grant_applications.includes(:grant_documents, :company)
    
    # Apply search to pipeline data too
    if @params[:search].present?
      sanitized_search = SanitizationService.sanitize_search_term(@params[:search])
      if sanitized_search.present?
        search_term = "%#{sanitized_search}%"
        if ActiveRecord::Base.connection.adapter_name.downcase == 'postgresql'
          all_applications = all_applications.where("title ILIKE ? OR description ILIKE ?", search_term, search_term)
        else
          search_term_upcase = "%#{sanitized_search.upcase}%"
          all_applications = all_applications.where("UPPER(title) LIKE ? OR UPPER(description) LIKE ?", search_term_upcase, search_term_upcase)
        end
      end
    end
    
    # Return raw applications grouped by stage - let presenter handle the formatting
    pipeline_data = {}
    GrantApplication.stages.keys.each do |stage|
      stage_applications = all_applications.where(stage: stage)
      pipeline_data[stage] = {
        applications: stage_applications,
        count: stage_applications.count,
        total_value: 0 # We can add value calculation later if needed
      }
    end
    
    pipeline_data
  end
end
