class RndClaim < ApplicationRecord
  belongs_to :company, optional: true
  has_many :rnd_claim_expenditures, dependent: :destroy
  
  
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
  
  # Search scope
  scope :search_by_content, ->(query) {
    where("title LIKE ? OR description LIKE ?", "%#{query}%", "%#{query}%")
  }
  
  # Sort scope
  scope :sorted_by, ->(field, direction = 'ASC') {
    case field
    when 'title'
      order("title #{direction.upcase}")
    when 'company'
      left_joins(:company).order("companies.name #{direction.upcase}")
    when 'start_date'
      order("start_date #{direction.upcase}")
    when 'total_expenditure'
      left_joins(:rnd_claim_expenditures)
        .group(:id)
        .order("SUM(rnd_claim_expenditures.amount) #{direction.upcase}")
    else
      order("created_at #{direction.upcase}")
    end
  }
  
  # Helper methods
  def total_expenditure
    rnd_claim_expenditures.sum(:amount)
  end
  
  def expenditure_by_type
    rnd_claim_expenditures.group(:expenditure_type).sum(:amount)
  end
  
  def duration_days
    return 0 unless start_date && end_date
    (end_date - start_date).to_i
  end
  
  def is_active?
    true # All claims are considered active now
  end
  
  def can_be_claimed?
    total_expenditure > 0
  end
  
  # Class method for complex filtering and sorting
  def self.filtered_and_sorted(current_user, search: nil, sort_by: 'created_at', sort_order: 'DESC')
    claims = if current_user.admin?
                 all
               elsif current_user.employee?
                 all
               else
                 all # All users can see all claims now
               end
    
    claims = claims.search_by_content(search) if search.present?
    claims.sorted_by(sort_by, sort_order)
  end
  
  # Global search method
  def self.search_global(query, current_user)
    base_query = if current_user.admin?
                   all
                 elsif current_user.employee?
                   all
                 else
                   all # All users can see all claims now
                 end
    
    # Search in claim fields
    base_query.where(
      "rnd_claims.title LIKE ? OR rnd_claims.description LIKE ? OR rnd_claims.qualifying_activities LIKE ? OR rnd_claims.technical_challenges LIKE ?",
      "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%"
    )
  end
  
  private
  
  def end_date_after_start_date
    return unless start_date && end_date
    
    if end_date <= start_date
      errors.add(:end_date, "must be after start date")
    end
  end
end
