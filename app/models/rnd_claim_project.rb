class RndClaimProject < ApplicationRecord
  belongs_to :rnd_claim
  
  validates :name, presence: true, length: { minimum: 1, maximum: 255 }
  validates :qualification_status, presence: true, inclusion: { in: %w[qualified disqualified] }
  validates :narrative_status, presence: true, inclusion: { in: %w[skip drafting drafted signed_off] }
  validates :name, uniqueness: { scope: :rnd_claim_id }
  
  # Scopes
  scope :qualified, -> { where(qualification_status: 'qualified') }
  scope :disqualified, -> { where(qualification_status: 'disqualified') }
  scope :by_narrative_status, ->(status) { where(narrative_status: status) }
  
  # Helper methods
  def qualified?
    qualification_status == 'qualified'
  end
  
  def disqualified?
    qualification_status == 'disqualified'
  end
  
  def narrative_skip?
    narrative_status == 'skip'
  end
  
  def narrative_drafting?
    narrative_status == 'drafting'
  end
  
  def narrative_drafted?
    narrative_status == 'drafted'
  end
  
  def narrative_signed_off?
    narrative_status == 'signed_off'
  end
  
  def qualification_status_display
    qualification_status.humanize
  end
  
  def narrative_status_display
    narrative_status.humanize.gsub('_', ' ').titleize
  end
end
