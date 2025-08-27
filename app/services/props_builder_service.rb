class PropsBuilderService
  def self.user_props(user)
    return nil unless user
    
    {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      isEmployee: user.employee?,
      isAdmin: user.admin?,
      isClient: user.client?,
      canManageClients: user.can_manage_clients?,
      canAccessGrantPipeline: user.can_access_grant_pipeline?,
      canViewInternalNotes: user.can_view_internal_notes?,
      availableFeatures: user.available_features.map(&:name)
    }
  end

  def self.rnd_project_props(project)
    {
      id: project.id,
      title: project.title,
      description: project.description,
      client: {
        id: project.client.id,
        name: project.client.name,
        email: project.client.email
      },
      start_date: project.start_date&.strftime("%Y-%m-%d"),
      end_date: project.end_date&.strftime("%Y-%m-%d"),
      status: project.status,
      qualifying_activities: project.qualifying_activities,
      technical_challenges: project.technical_challenges,
      total_expenditure: project.total_expenditure,
      expenditure_by_type: project.expenditure_by_type,
      duration_days: project.duration_days,
      is_active: project.is_active?,
      can_be_claimed: project.can_be_claimed?,
      created_at: project.created_at.strftime("%B %d, %Y"),
      updated_at: project.updated_at.strftime("%B %d, %Y")
    }
  end

  def self.note_props(note)
    {
      id: note.id,
      title: note.title,
      content: note.content,
      created_at: format_date(note.created_at),
      updated_at: format_date(note.updated_at)
    }
  end

  def self.todo_props(todo)
    {
      id: todo.id,
      title: todo.title,
      description: todo.description,
      completed: todo.completed,
      priority: todo.priority,
      due_date: todo.due_date&.strftime("%Y-%m-%d"),
      created_at: format_date(todo.created_at),
      due_date_formatted: format_due_date(todo.due_date),
      overdue: todo.overdue?,
      due_soon: todo.due_soon?
    }
  end

  def self.message_props(message)
    {
      id: message.id,
      subject: message.subject,
      content: message.content,
      sender_name: message.sender.name,
      recipient_name: message.recipient.name,
      client_name: message.client&.name,
      message_type: message.message_type,
      is_internal: message.is_internal?,
      created_at: format_date(message.created_at)
    }
  end

  def self.file_item_props(file_item)
    {
      id: file_item.id,
      name: file_item.name,
      file_type: file_item.file_type,
      file_size: file_item.file_size,
      formatted_size: format_file_size(file_item.file_size),
      created_at: format_date(file_item.created_at)
    }
  end

  def self.grant_application_props(application)
    {
      id: application.id,
      title: application.title,
      status: application.status,
      submission_date: application.submission_date&.strftime("%Y-%m-%d"),
      created_at: format_date(application.created_at)
    }
  end

  private

  def self.format_date(date)
    date.strftime("%B %d, %Y")
  end

  def self.format_due_date(date)
    return "No due date" unless date
    date.strftime("%B %d, %Y")
  end

  def self.format_file_size(bytes)
    return "0 Bytes" if bytes.nil? || bytes == 0
    k = 1024
    sizes = ['Bytes', 'KB', 'MB', 'GB']
    i = Math.log(bytes) / Math.log(k)
    "#{sprintf('%.1f', bytes / k**i)} #{sizes[i.floor]}"
  end
end
