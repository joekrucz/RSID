class Todo < ApplicationRecord
  belongs_to :user
  
  validates :title, presence: true, length: { minimum: 1, maximum: 255 }
  validates :priority, inclusion: { in: %w[low medium high] }, allow_nil: true
  validates :user, presence: true
  validates :completed, inclusion: { in: [true, false] }, allow_nil: true
  
  before_save :ensure_boolean_completed
  
  scope :by_user, ->(user) { where(user: user) }
  scope :active, -> { where(completed: false) }
  scope :completed, -> { where(completed: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :due_soon, -> { where('due_date <= ?', 7.days.from_now).where(completed: false) }
  scope :overdue, -> { where('due_date < ? AND completed = ?', Date.current, false) }
  scope :completed_today, -> { where(completed: true, updated_at: Date.current.all_day) }
  
  # Search scope
  scope :search_by_content, ->(query) { 
    where("title LIKE ? OR description LIKE ?", "%#{query}%", "%#{query}%") 
  }
  
  # Filter scope
  scope :filter_by_status, ->(status) {
    case status
    when 'active'
      where(completed: false)
    when 'completed'
      where(completed: true)
    else
      all
    end
  }
  
  # Sort scope
  scope :sorted_by, ->(field, direction = 'ASC') {
    case field
    when 'title'
      order("title #{direction.upcase}")
    when 'priority'
      order("priority #{direction.upcase}")
    when 'due_date'
      order("due_date #{direction.upcase} NULLS LAST")
    when 'completed'
      order("completed #{direction.upcase}")
    when 'updated_at'
      order("updated_at #{direction.upcase}")
    else
      order("created_at #{direction.upcase}")
    end
  }
  
  def overdue?
    due_date && due_date < Date.current && !completed
  end
  
  def due_soon?
    due_date && due_date <= 7.days.from_now && due_date >= Date.current && !completed
  end
  
  # Class method for complex filtering and sorting
  def self.filtered_and_sorted(user, search: nil, filter: nil, sort_by: 'created_at', sort_order: 'DESC')
    todos = by_user(user)
    
    todos = todos.search_by_content(search) if search.present?
    todos = todos.filter_by_status(filter) if filter.present?
    todos.sorted_by(sort_by, sort_order)
  end
  

  
  private
  
  def ensure_boolean_completed
    self.completed = false if completed.blank?
  end
end
