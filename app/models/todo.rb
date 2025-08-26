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
  
  def overdue?
    due_date && due_date < Date.current && !completed
  end
  
  def due_soon?
    due_date && due_date <= 7.days.from_now && due_date >= Date.current && !completed
  end
  
  def created_at_formatted
    created_at.strftime("%B %d, %Y")
  end
  
  def due_date_formatted
    due_date&.strftime("%B %d, %Y")
  end
  
  private
  
  def ensure_boolean_completed
    self.completed = false if completed.blank?
  end
end
