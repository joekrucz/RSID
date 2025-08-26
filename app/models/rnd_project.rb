class RndProject < ApplicationRecord
  belongs_to :client, class_name: 'User'
  has_many :rnd_expenditures, dependent: :destroy
  
  # Status enum
  enum :status, { draft: 0, active: 1, completed: 2, ready_for_claim: 3 }
  
  # Validations
  validates :title, presence: true, length: { minimum: 3 }
  validates :description, presence: true, length: { minimum: 10 }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :qualifying_activities, presence: true, length: { minimum: 10 }
  validates :technical_challenges, presence: true, length: { minimum: 10 }
  validate :end_date_after_start_date
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_client, ->(client_id) { where(client_id: client_id) }
  scope :active_projects, -> { where(status: [:active, :completed, :ready_for_claim]) }
  
  # Helper methods
  def total_expenditure
    rnd_expenditures.sum(:amount)
  end
  
  def expenditure_by_type
    rnd_expenditures.group(:expenditure_type).sum(:amount)
  end
  
  def duration_days
    return 0 unless start_date && end_date
    (end_date - start_date).to_i
  end
  
  def is_active?
    active? || completed? || ready_for_claim?
  end
  
  def can_be_claimed?
    ready_for_claim? && total_expenditure > 0
  end
  
  private
  
  def end_date_after_start_date
    return unless start_date && end_date
    
    if end_date <= start_date
      errors.add(:end_date, "must be after start date")
    end
  end
end
