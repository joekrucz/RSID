class Client < ApplicationRecord
  belongs_to :user
  belongs_to :employee, class_name: 'User', optional: true
  
  # Message associations
  has_many :messages, dependent: :destroy
  
  validates :name, presence: true, length: { minimum: 2 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :company, presence: true
  validates :sector, presence: true
  validates :user, presence: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :by_sector, ->(sector) { where(sector: sector) }
  scope :search_by_name, ->(query) { where("name LIKE ? OR company LIKE ?", "%#{query}%", "%#{query}%") }
  scope :assigned_to_employee, ->(employee) { where(employee: employee) }
  scope :unassigned, -> { where(employee: nil) }
  
  def created_at_formatted
    created_at.strftime("%B %d, %Y")
  end
  
  def updated_at_formatted
    updated_at.strftime("%B %d, %Y")
  end
  
  def assigned?
    employee.present?
  end
  
  def assign_to_employee(employee_user)
    update(employee: employee_user)
  end
  
  def unassign
    update(employee: nil)
  end
  
  def recent_messages(limit = 5)
    messages.recent.limit(limit)
  end
  
  def internal_messages
    messages.internal_only
  end
  
  def client_visible_messages
    messages.client_visible
  end
end
