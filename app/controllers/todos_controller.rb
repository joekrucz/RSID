class TodosController < ApplicationController
  before_action :require_login
  before_action :set_todo, only: [:show, :edit, :update, :destroy]

  def index
    Rails.logger.info "Todos accessed by user: #{@current_user.name}"
    
    # Get search and sort parameters
    search = params[:search]&.strip
    sort_by = params[:sort_by] || 'created_at'
    sort_order = params[:sort_order] || 'desc'
    filter = params[:filter] || 'all'
    
    # Start with user's todos
    todos = @current_user.todos
    
    # Apply search filter if provided
    if search.present?
      todos = todos.where("title LIKE ? OR description LIKE ?", "%#{search}%", "%#{search}%")
    end
    
    # Apply status filter
    case filter
    when 'active'
      todos = todos.where(completed: false)
    when 'completed'
      todos = todos.where(completed: true)
    end
    
    # Apply sorting
    case sort_by
    when 'title'
      todos = todos.order("title #{sort_order.upcase}")
    when 'priority'
      todos = todos.order("priority #{sort_order.upcase}")
    when 'due_date'
      todos = todos.order("due_date #{sort_order.upcase} NULLS LAST")
    when 'completed'
      todos = todos.order("completed #{sort_order.upcase}")
    when 'updated_at'
      todos = todos.order("updated_at #{sort_order.upcase}")
    else # default to created_at
      todos = todos.order("created_at #{sort_order.upcase}")
    end
    
    render inertia: 'Todos/Index', props: {
      user: user_props,
      todos: todos.map { |todo| todo_props(todo) },
      search: search,
      sort_by: sort_by,
      sort_order: sort_order,
      filter: filter
    }
  end

  def show
    render inertia: 'Todos/Show', props: {
      user: user_props,
      todo: todo_props(@todo)
    }
  end

  def edit
    render inertia: 'Todos/Index', props: {
      user: user_props,
      todos: @current_user.todos.recent.map { |todo| todo_props(todo) },
      editing_todo: todo_props(@todo)
    }
  end

  def create
    @todo = @current_user.todos.build(todo_params)
    
    if @todo.save
      render inertia: 'Todos/Index', props: {
        user: user_props,
        todos: @current_user.todos.recent.map { |todo| todo_props(todo) },
        success_message: "Todo added successfully!"
      }
    else
      render inertia: 'Todos/Index', props: {
        user: user_props,
        todos: @current_user.todos.recent.map { |todo| todo_props(todo) },
        errors: @todo.errors.full_messages,
        todo: { 
          title: todo_params[:title], 
          description: todo_params[:description],
          priority: todo_params[:priority],
          due_date: todo_params[:due_date]
        }
      }
    end
  end

  def update
    if @todo.update(todo_params)
      render inertia: 'Todos/Index', props: {
        user: user_props,
        todos: @current_user.todos.recent.map { |todo| todo_props(todo) },
        success_message: "Todo updated successfully!"
      }
    else
      render inertia: 'Todos/Index', props: {
        user: user_props,
        todos: @current_user.todos.recent.map { |todo| todo_props(todo) },
        errors: @todo.errors.full_messages,
        editing_todo: todo_props(@todo)
      }
    end
  end

  def destroy
    @todo.destroy
    
    render inertia: 'Todos/Index', props: {
      user: user_props,
      todos: @current_user.todos.recent.map { |todo| todo_props(todo) },
      success_message: "Todo deleted successfully!"
    }
  end

  def toggle
    @todo = @current_user.todos.find(params[:id])
    @todo.update(completed: !@todo.completed)
    
    render inertia: 'Todos/Index', props: {
      user: user_props,
      todos: @current_user.todos.recent.map { |todo| todo_props(todo) },
      success_message: @todo.completed ? "Todo completed! 🎉" : "Todo marked as incomplete"
    }
  end

  def clear_completed
    @current_user.todos.completed.destroy_all
    
    render inertia: 'Todos/Index', props: {
      user: user_props,
      todos: @current_user.todos.recent.map { |todo| todo_props(todo) },
      success_message: "Completed todos cleared!"
    }
  end

  private

  def set_todo
    @todo = @current_user.todos.find(params[:id])
  end

  def todo_params
    params.require(:todo).permit(:title, :description, :completed, :priority, :due_date)
  end

  def todo_props(todo)
    {
      id: todo.id,
      title: todo.title,
      description: todo.description,
      completed: todo.completed,
      priority: todo.priority,
      due_date: todo.due_date&.strftime("%Y-%m-%d"),
      created_at: todo.created_at_formatted,
      due_date_formatted: todo.due_date_formatted,
      overdue: todo.overdue?,
      due_soon: todo.due_soon?
    }
  end
end 