module ApplicationHelper
  # Date formatting helpers
  def format_date(date, format: "%B %d, %Y")
    return "N/A" unless date
    date.strftime(format)
  end
  
  def format_datetime(datetime, format: "%B %d, %Y at %I:%M %p")
    return "N/A" unless datetime
    datetime.strftime(format)
  end
  
  def format_due_date(due_date)
    return "No due date set" unless due_date
    due_date.strftime("%B %d, %Y")
  end
  
  # File size formatting helper
  def format_file_size(size_in_bytes)
    return "Unknown" unless size_in_bytes
    
    units = %w[B KB MB GB TB]
    size = size_in_bytes.to_f
    unit_index = 0
    
    while size >= 1024 && unit_index < units.length - 1
      size /= 1024
      unit_index += 1
    end
    
    "#{size.round(1)} #{units[unit_index]}"
  end
  
  # Status color helpers
  def grant_application_status_color(status)
    case status.to_s
    when 'draft'
      'badge-neutral'
    when 'submitted'
      'badge-info'
    when 'under_review'
      'badge-warning'
    when 'approved'
      'badge-success'
    when 'rejected'
      'badge-error'
    when 'completed'
      'badge-success'
    else
      'badge-neutral'
    end
  end
  
  def rnd_project_status_color(status)
    case status.to_s
    when 'draft'
      'badge-neutral'
    when 'active'
      'badge-info'
    when 'completed'
      'badge-success'
    when 'ready_for_claim'
      'badge-warning'
    else
      'badge-neutral'
    end
  end
  
  def todo_priority_color(priority)
    case priority.to_s
    when 'high'
      'badge-error'
    when 'medium'
      'badge-warning'
    when 'low'
      'badge-success'
    else
      'badge-neutral'
    end
  end
  
  # Status display name helpers
  def grant_application_status_display(status)
    status.to_s.replace('_', ' ').titleize
  end
  
  def rnd_project_status_display(status)
    status.to_s.replace('_', ' ').titleize
  end
  
  # File type icon helpers
  def file_type_icon(file_type)
    case file_type.to_s.downcase
    when 'pdf'
      'fas fa-file-pdf text-red-500'
    when 'doc', 'docx'
      'fas fa-file-word text-blue-500'
    when 'xls', 'xlsx'
      'fas fa-file-excel text-green-500'
    when 'ppt', 'pptx'
      'fas fa-file-powerpoint text-orange-500'
    when 'txt'
      'fas fa-file-alt text-gray-500'
    when 'jpg', 'jpeg', 'png', 'gif'
      'fas fa-file-image text-purple-500'
    else
      'fas fa-file text-gray-500'
    end
  end
end
