class GrantCompetition < ApplicationRecord
  has_many :grant_applications, dependent: :nullify

  validates :grant_name, presence: true, length: { maximum: 255 }
  validates :deadline, presence: true
  validates :funding_body, presence: true, length: { maximum: 255 }
  validates :competition_link, presence: true, format: { with: URI::regexp(%w[http https]), message: "must be a valid URL" }

  scope :upcoming, -> { where('deadline > ?', Time.current) }
  scope :past, -> { where('deadline <= ?', Time.current) }
  scope :by_funding_body, ->(body) { where('funding_body ILIKE ?', "%#{body}%") }

  def upcoming?
    deadline > Time.current
  end

  def past?
    deadline <= Time.current
  end

  def days_until_deadline
    return nil if past?
    (deadline.to_date - Date.current).to_i
  end

  def status
    upcoming? ? 'upcoming' : 'past'
  end
end
