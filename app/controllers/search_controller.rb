class SearchController < ApplicationController
  before_action :require_login

  def index
    query = SanitizationService.sanitize_search_query(params[:q])
    filters = params[:filters] || {}
    
    log_user_action("performed_search", { query: query, filters: filters })
    
    results = if query.present?
      perform_search(query, filters)
    else
      { projects: [], messages: [], users: [] }
    end
    
    render inertia: 'Search/Index', props: {
      user: user_props,
      query: query,
      filters: filters,
      results: results,
      pagination: {
        page: page,
        per_page: per_page,
        total_results: results.values_at(:projects_total, :messages_total, :users_total).compact.sum
      }
    }
  end

  private

  def perform_search(query, filters)
    results = {}
    
    # Get pagination parameters
    page = params[:page]&.to_i || 1
    per_page = [params[:per_page]&.to_i || 10, Rails.application.config.x.max_search_results].min
    
    # Search R&D Claims
    if should_search?('claims', filters)
      claims_query = RndClaim.search_global(query, @current_user)
      results[:claims] = claims_query
        .offset((page - 1) * per_page)
        .limit(per_page)
        .map { |claim| PropsBuilderService.rnd_claim_props(claim) }
      results[:claims_total] = claims_query.count
    end
    
    # Search Messages
    if should_search?('messages', filters)
      messages_query = Message.search_global(query, @current_user)
      results[:messages] = messages_query
        .offset((page - 1) * per_page)
        .limit(per_page)
        .map { |message| PropsBuilderService.message_props(message) }
      results[:messages_total] = messages_query.count
    end
    
    # Search Users (admin/employee only)
    if should_search?('users', filters) && @current_user.employee?
      users_query = User.search_global(query, @current_user)
      results[:users] = users_query
        .offset((page - 1) * per_page)
        .limit(per_page)
        .map { |user| PropsBuilderService.user_props(user) }
      results[:users_total] = users_query.count
    end
    
    results
  end

  def should_search?(type, filters)
    return true if filters.empty?
    filters[type] == 'true' || filters[type] == true
  end

  def user_props
    {
      id: @current_user.id,
      name: @current_user.name,
      email: @current_user.email,
      role: @current_user.role
    }
  end
end