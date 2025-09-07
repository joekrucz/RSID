class GrantApplication < ApplicationRecord
  belongs_to :user
  belongs_to :company, optional: true
  has_many :grant_documents, dependent: :destroy
  has_many :grant_checklist_items, dependent: :destroy
  
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
  
  # Stage enum for high-level pipeline state
  attribute :stage, :integer, default: 0
  enum :stage, {
    client_acquisition_project_qualification: 0,
    client_invoiced: 1,
    invoice_paid: 2,
    preparing_for_kick_off_aml_resourcing: 3,
    kicked_off_in_progress: 4,
    submitted: 5,
    awaiting_funding_decision: 6,
    application_successful_or_not_successful: 7,
    resub_due: 8,
    success_fee_invoiced: 9,
    success_fee_paid: 10
  }, prefix: true
  
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
    true
  end
  
  def can_submit?
    false
  end
end
