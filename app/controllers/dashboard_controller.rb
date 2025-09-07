class DashboardController < ApplicationController
  before_action :require_login

  def index
    Rails.logger.info "Dashboard accessed by user: #{@current_user.name} (Role: #{@current_user.role})"
    
    # Role-specific stats
    stats = get_role_specific_stats
    
    # Role-specific recent activity
    recent_activity = get_role_specific_activity
    
    # Role-specific content summaries
    content_summaries = get_role_specific_summaries
    
    # Role-specific storage overview
    storage_overview = get_role_specific_storage
    
    render inertia: 'Dashboard/Index', props: {
      user: user_props,
      stats: stats,
      recent_activity: recent_activity,
      content_summaries: content_summaries,
      storage_overview: storage_overview
    }
  end

  private

  def get_role_specific_stats
    base_stats = {
      files: @current_user.file_items.count,
      notes: @current_user.notes.count,
      todos: @current_user.todos.count,
      active_todos: @current_user.todos.where(completed: false).count,
      completed_todos: @current_user.todos.where(completed: true).count,
      completed_today: @current_user.todos.where(completed: true, updated_at: Date.current.all_day).count,
      overdue_todos: @current_user.todos.where('due_date < ? AND completed = ?', Date.current, false).count,
      storage_used: @current_user.file_items.sum(:file_size) || 0,
      grant_applications: @current_user.grant_applications.count,
      grant_applications_overdue: @current_user.grant_applications.overdue.count,
      rnd_claims: get_accessible_rnd_claims.count,
      rnd_claims_draft: get_accessible_rnd_claims.where(stage: 'upcoming').count,
      rnd_claims_ready_for_claim: get_accessible_rnd_claims.where(stage: 'finalised').count,
      rnd_claims_total_value: get_accessible_rnd_claims.sum(&:total_expenditure),
      companies: get_accessible_companies.count,
      grant_competitions: get_accessible_grant_competitions.count
    }
    
    # Add role-specific stats
    if @current_user.employee?
      base_stats[:clients] = @current_user.assigned_clients.count
      base_stats[:unassigned_clients] = Client.unassigned.count
    elsif @current_user.client?
      base_stats[:clients] = 1 # They are their own client
    else
      base_stats[:clients] = 0
    end
    
    # Add admin-specific stats
    if @current_user.admin?
      base_stats[:people] = User.count
      base_stats[:total_users] = User.count
    end
    
    # Calculate completion rate
    completion_rate = base_stats[:todos] > 0 ? (base_stats[:completed_todos].to_f / base_stats[:todos] * 100).round(1) : 0
    base_stats[:completion_rate] = completion_rate
    
    base_stats
  end

  def get_role_specific_activity
    base_activity = {
      notes: @current_user.notes.recent.limit(3).map { |note| note_props(note) },
      todos: @current_user.todos.recent.limit(5).map { |todo| todo_props(todo) },
      files: @current_user.file_items.recent.limit(3).map { |file| file_props(file) },
      grant_applications: @current_user.grant_applications.order(created_at: :desc).limit(3).map { |app| grant_application_props(app) },
      rnd_claims: get_accessible_rnd_claims.order(created_at: :desc).limit(3).map { |claim| rnd_claim_props(claim) },
      companies: get_accessible_companies.order(created_at: :desc).limit(3).map { |company| company_props(company) },
      grant_competitions: get_accessible_grant_competitions.order(created_at: :desc).limit(3).map { |competition| grant_competition_props(competition) }
    }
    
    # Add role-specific activity
    if @current_user.employee?
      base_activity[:clients] = @current_user.assigned_clients.recent.limit(3).map { |client| client_props(client) }
    elsif @current_user.client?
      base_activity[:clients] = [@current_user.client_profile].compact.map { |client| client_props(client) }
    else
      base_activity[:clients] = []
    end
    
    # Add admin-specific activity
    if @current_user.admin?
      base_activity[:people] = User.order(created_at: :desc).limit(3).map { |user| user_summary_props(user) }
    end
    
    base_activity
  end

  def get_role_specific_summaries
    base_summaries = {
      notes: {
        total: @current_user.notes.count,
        recent: @current_user.notes.recent.limit(1).first&.title || 'No notes yet',
        created_this_week: @current_user.notes.where(created_at: 1.week.ago..Time.current).count
      },
      todos: {
        total: @current_user.todos.count,
        active: @current_user.todos.where(completed: false).count,
        completed: @current_user.todos.where(completed: true).count,
        completed_today: @current_user.todos.where(completed: true, updated_at: Date.current.all_day).count,
        overdue: @current_user.todos.where('due_date < ? AND completed = ?', Date.current, false).count,
        completion_rate: @current_user.todos.count > 0 ? (@current_user.todos.where(completed: true).count.to_f / @current_user.todos.count * 100).round(1) : 0
      },
      files: {
        total: @current_user.file_items.count,
        storage_used: format_storage(@current_user.file_items.sum(:file_size) || 0),
        by_category: @current_user.file_items.group(:category).count,
        by_type: @current_user.file_items.group(:file_type).count
      }
    }
    
    # Add role-specific summaries
    if @current_user.employee?
      base_summaries[:clients] = {
        total: @current_user.assigned_clients.count,
        unassigned: Client.unassigned.count,
        by_sector: @current_user.assigned_clients.group(:sector).count
      }
    elsif @current_user.client?
      base_summaries[:clients] = {
        total: 1,
        profile_complete: @current_user.client_profile.present?,
        sector: @current_user.client_profile&.sector || 'Not set'
      }
    end
    
    base_summaries
  end

  def get_role_specific_storage
    base_storage = {
      total_files: @current_user.file_items.count,
      total_storage: format_storage(@current_user.file_items.sum(:file_size) || 0),
      by_category: @current_user.file_items.group(:category).count,
      by_type: @current_user.file_items.group(:file_type).count,
      recent_uploads: @current_user.file_items.recent.limit(5).map { |file| file_props(file) }
    }
    
    base_storage
  end

  def note_props(note)
    {
      id: note.id,
      title: note.title,
      content: note.content.truncate(100),
      created_at: format_date(note.created_at),
      updated_at: format_date(note.updated_at)
    }
  end

  def todo_props(todo)
    {
      id: todo.id,
      title: todo.title,
      completed: todo.completed,
      priority: todo.priority,
      due_date: format_due_date(todo.due_date),
      overdue: todo.overdue?,
      due_soon: todo.due_soon?,
      created_at: format_date(todo.created_at)
    }
  end

  def file_props(file)
    {
      id: file.id,
      name: file.name,
      original_filename: file.original_filename,
      file_type: file.file_type_category,
      file_size: format_file_size(file.file_size),
      category: file.category,
      previewable: file.previewable?,
      image: file.image?,
      created_at: format_date(file.created_at)
    }
  end

  def client_props(client)
    {
      id: client.id,
      name: client.name,
      email: client.email,
      company: client.company,
      sector: client.sector,
      created_at: format_date(client.created_at)
    }
  end
  
  def grant_application_props(application)
    {
      id: application.id,
      title: application.title,
      deadline: format_date(application.deadline),
      days_until_deadline: application.days_until_deadline,
      overdue: application.overdue?,
      created_at: format_date(application.created_at)
    }
  end

  def rnd_claim_props(claim)
    {
      id: claim.id,
      title: claim.title,
      total_expenditure: claim.total_expenditure,
      client_name: claim.company&.name || 'No Company',
      created_at: format_date(claim.created_at)
    }
  end

  def company_props(company)
    {
      id: company.id,
      name: company.name,
      website: company.website,
      created_at: format_date(company.created_at)
    }
  end

  def grant_competition_props(competition)
    {
      id: competition.id,
      grant_name: competition.grant_name,
      funding_body: competition.funding_body,
      deadline: format_date(competition.deadline),
      created_at: format_date(competition.created_at)
    }
  end

  def user_summary_props(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      created_at: format_date(user.created_at)
    }
  end

  def get_accessible_rnd_claims
    if @current_user.admin?
      RndClaim.all
    elsif @current_user.employee?
      RndClaim.all # Employees can see all claims
    else
      RndClaim.where(client: @current_user) # Clients can only see their own claims
    end
  end

  def get_accessible_companies
    if @current_user.admin? || @current_user.employee?
      Company.all
    else
      Company.none # Clients don't see companies directly
    end
  end

  def get_accessible_grant_competitions
    if @current_user.admin? || @current_user.employee?
      GrantCompetition.all
    else
      GrantCompetition.none # Clients don't see competitions directly
    end
  end



  def format_storage(bytes)
    return '0 B' if bytes.nil? || bytes == 0
    
    units = %w[B KB MB GB TB]
    size = bytes.to_f
    unit_index = 0
    
    while size >= 1024 && unit_index < units.length - 1
      size /= 1024
      unit_index += 1
    end
    
    "#{size.round(1)} #{units[unit_index]}"
  end
end
