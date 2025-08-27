class GrantApplication < ApplicationRecord
  belongs_to :user
  has_many :grant_documents, dependent: :destroy
  
  # Status enum with explicit type
  attribute :status, :integer, default: 0
  enum :status, { 
    draft: 0, 
    submitted: 1, 
    under_review: 2, 
    approved: 3, 
    rejected: 4, 
    completed: 5 
  }
  
  validates :title, presence: true, length: { minimum: 3, maximum: 255 }
  validates :description, presence: true, length: { minimum: 10 }
  validates :deadline, presence: true
  validates :status, presence: true
  
  # Scopes
  scope :upcoming_deadlines, -> { where('deadline > ?', Time.current).order(:deadline) }
  scope :overdue, -> { where('deadline < ? AND status IN (?)', Time.current, [0, 1, 2]) }
  scope :by_status, ->(status) { where(status: status) }
  
  # Search scope
  scope :search_by_content, ->(query) {
    where("title LIKE ? OR description LIKE ?", "%#{query}%", "%#{query}%")
  }
  
  # Helper methods
  def overdue?
    deadline < Time.current && ['draft', 'submitted', 'under_review'].include?(status)
  end
  
  def days_until_deadline
    return nil if deadline.nil?
    (deadline.to_date - Date.current).to_i
  end
  

  
  def can_edit?
    ['draft'].include?(status)
  end
  
  def can_submit?
    ['draft'].include?(status)
  end
end
