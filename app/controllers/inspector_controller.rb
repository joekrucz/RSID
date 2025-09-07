class InspectorController < ApplicationController
  before_action :require_login
  before_action :require_admin

  def index
    Rails.logger.info "App Inspector accessed by admin: #{@current_user.name}"
    
    render inertia: 'Inspector/Index', props: {
      user: user_props,
      app_state: build_app_state,
      database_stats: build_database_stats,
      sample_data: build_sample_data,
      controller_info: build_controller_info,
      feature_flags: build_feature_flags_info
    }
  end

  private

  def build_app_state
    {
      current_user: {
        id: @current_user.id,
        name: @current_user.name,
        email: @current_user.email,
        role: @current_user.role,
        permissions: {
          can_manage_clients: @current_user.can_manage_clients?,
          can_access_grant_pipeline: @current_user.can_access_grant_pipeline?,
          can_view_internal_notes: @current_user.can_view_internal_notes?
        },
        available_features: @current_user.available_features.map(&:name),
        session_id: session.id,
        session_keys: session.keys
      },
      environment: {
        rails_env: Rails.env,
        database: ActiveRecord::Base.connection.adapter_name,
        timezone: Time.zone.name
      }
    }
  end

  def build_database_stats
    {
      users: {
        total: User.count,
        by_role: {
          clients: User.clients.count,
          employees: User.employees.count,
          admins: User.admins.count
        }
      },
      rnd_projects: {
        total: RndProject.count,
        by_status: RndProject.group(:status).count
      },
      rnd_expenditures: {
        total: RndExpenditure.count,
        total_amount: RndExpenditure.sum(:amount)
      },
      notes: {
        total: Note.count
      },
      todos: {
        total: Todo.count,
        completed: Todo.where(completed: true).count,
        pending: Todo.where(completed: false).count
      },
      file_items: {
        total: FileItem.count,
        total_size: FileItem.sum(:file_size) || 0
      },
      grant_applications: {
        total: GrantApplication.count,
        by_stage: GrantApplication.group(:stage).count
      },
      messages: {
        total: Message.count
      },
      clients: {
        total: Client.count,
        unassigned: Client.unassigned.count
      }
    }
  end

  def build_sample_data
    {
      recent_users: User.order(created_at: :desc).limit(3).map { |user| user_inspector_props(user) },
      recent_projects: RndProject.includes(:client).order(created_at: :desc).limit(3).map { |project| project_inspector_props(project) },
      recent_notes: Note.includes(:user).order(created_at: :desc).limit(3).map { |note| note_inspector_props(note) },
      recent_todos: Todo.includes(:user).order(created_at: :desc).limit(3).map { |todo| todo_inspector_props(todo) }
    }
  end

  def build_controller_info
    {
      current_controller: controller_name,
      current_action: action_name,
      request_method: request.method,
      request_path: request.path,
      request_params: params.except(:controller, :action, :format),
      available_routes: Rails.application.routes.routes.map(&:path).compact.uniq.map(&:to_s).sort
    }
  end

  def build_feature_flags_info
    {
      all_flags: FeatureFlag.all.map { |flag| feature_flag_inspector_props(flag) },
      enabled_flags: FeatureFlag.enabled.map(&:name),
      user_enabled_flags: @current_user.available_features.map(&:name)
    }
  end

  def user_inspector_props(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      created_at: user.created_at.strftime("%Y-%m-%d %H:%M:%S"),
      associations_count: {
        notes: user.notes.count,
        todos: user.todos.count,
        rnd_projects: RndProject.where(client: user).count,
        file_items: user.file_items.count
      }
    }
  end

  def project_inspector_props(project)
    {
      id: project.id,
      title: project.title,
      status: project.status,
      client_name: project.client.name,
      total_expenditure: project.total_expenditure,
      created_at: project.created_at.strftime("%Y-%m-%d %H:%M:%S"),
      expenditures_count: project.rnd_expenditures.count
    }
  end

  def note_inspector_props(note)
    {
      id: note.id,
      title: note.title,
      user_name: note.user.name,
      created_at: note.created_at.strftime("%Y-%m-%d %H:%M:%S"),
      content_preview: note.content&.truncate(50)
    }
  end

  def todo_inspector_props(todo)
    {
      id: todo.id,
      title: todo.title,
      completed: todo.completed,
      user_name: todo.user.name,
      created_at: todo.created_at.strftime("%Y-%m-%d %H:%M:%S"),
      due_date: todo.due_date&.strftime("%Y-%m-%d")
    }
  end

  def feature_flag_inspector_props(flag)
    {
      id: flag.id,
      name: flag.name,
      enabled: flag.enabled,
      description: flag.description,
      users_with_access: flag.user_feature_accesses.count
    }
  end
end
