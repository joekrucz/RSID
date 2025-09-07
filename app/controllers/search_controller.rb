class SearchController < ApplicationController
  before_action :require_login

  def index
    query = SanitizationService.sanitize_search_query(params[:q])
    filters = params[:filters] || {}
    
    log_user_action("performed_search", { query: query, filters: filters })
    
    results = if query.present?
      perform_search(query, filters)
    else
      { projects: [], notes: [], todos: [], messages: [], users: [] }
    end
    
    render inertia: 'Search/Index', props: {
      user: user_props,
      query: query,
      filters: filters,
      results: results,
      pagination: {
        page: page,
        per_page: per_page,
        total_results: results.values_at(:projects_total, :notes_total, :todos_total, :messages_total, :users_total).compact.sum
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
    
    # Search Notes
    if should_search?('notes', filters)
      notes_query = Note.search_global(query, @current_user)
      results[:notes] = notes_query
        .offset((page - 1) * per_page)
        .limit(per_page)
        .map { |note| PropsBuilderService.note_props(note) }
      results[:notes_total] = notes_query.count
    end
    
    # Search Todos
    if should_search?('todos', filters)
      todos_query = Todo.search_global(query, @current_user)
      results[:todos] = todos_query
        .offset((page - 1) * per_page)
        .limit(per_page)
        .map { |todo| PropsBuilderService.todo_props(todo) }
      results[:todos_total] = todos_query.count
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
end
