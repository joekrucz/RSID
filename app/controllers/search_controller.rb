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
      total_results: results.values.sum(&:length)
    }
  end

  private

  def perform_search(query, filters)
    results = {}
    
    # Search R&D Projects
    if should_search?('projects', filters)
      results[:projects] = RndProject.search_global(query, @current_user)
        .limit(10)
        .map { |project| PropsBuilderService.rnd_project_props(project) }
    end
    
    # Search Notes
    if should_search?('notes', filters)
      results[:notes] = Note.search_global(query, @current_user)
        .limit(10)
        .map { |note| PropsBuilderService.note_props(note) }
    end
    
    # Search Todos
    if should_search?('todos', filters)
      results[:todos] = Todo.search_global(query, @current_user)
        .limit(10)
        .map { |todo| PropsBuilderService.todo_props(todo) }
    end
    
    # Search Messages
    if should_search?('messages', filters)
      results[:messages] = Message.search_global(query, @current_user)
        .limit(10)
        .map { |message| PropsBuilderService.message_props(message) }
    end
    
    # Search Users (admin/employee only)
    if should_search?('users', filters) && @current_user.employee?
      results[:users] = User.search_global(query, @current_user)
        .limit(10)
        .map { |user| PropsBuilderService.user_props(user) }
    end
    
    results
  end

  def should_search?(type, filters)
    return true if filters.empty?
    filters[type] == 'true' || filters[type] == true
  end
end
