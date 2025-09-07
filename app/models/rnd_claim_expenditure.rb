class RndClaimExpenditure < ApplicationRecord
  belongs_to :rnd_claim
  
  # Expenditure type enum
  enum :expenditure_type, { 
    staff: 0, 
    materials: 1, 
    subcontractors: 2, 
    software: 3, 
    equipment: 4, 
    utilities: 5 
  }
  
  # Validations
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :description, presence: true, length: { minimum: 5 }
  validates :date, presence: true
  validates :expenditure_type, presence: true
  
  # Scopes
  scope :recent, -> { order(date: :desc) }
  scope :by_type, ->(type) { where(expenditure_type: type) }
  scope :in_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  
  # Helper methods
  def qualifying_amount
    case expenditure_type
    when 'staff'
      amount # 100% qualifying
    when 'materials'
      amount # 100% qualifying
    when 'subcontractors'
      amount * 0.65 # 65% qualifying
    when 'software'
      amount # 100% qualifying
    when 'equipment'
      amount # 100% qualifying
    when 'utilities'
      amount # 100% qualifying
    else
      amount
    end
  end
  
  def is_qualifying?
    qualifying_amount > 0
  end
  
  def formatted_amount
    "£#{amount.to_f.round(2)}"
  end
  
  def formatted_qualifying_amount
    "£#{qualifying_amount.to_f.round(2)}"
  end
end
