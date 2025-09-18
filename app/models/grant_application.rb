# GrantApplication Model
# 
# This model represents a grant application in the system.
# It tracks the entire lifecycle from initial qualification to final payment.
# 
# The stage enum represents the business workflow:
# 0-2: Client acquisition and payment phases
# 3-4: Project preparation and execution
# 5-6: Submission and decision phases  
# 7-10: Final outcome and success fee collection
#
# NOTE: The stage names are verbose for clarity in the UI mockup.
# In production, consider shorter, more technical stage names.
class GrantApplication < ApplicationRecord
  belongs_to :user
  belongs_to :company, optional: true
  belongs_to :grant_competition, optional: true
  has_many :grant_documents, dependent: :destroy
  has_many :grant_checklist_items, dependent: :destroy
  
  
  # Stage enum for high-level pipeline state
  # This represents the business workflow from client acquisition to success fee payment
  attribute :stage, :integer, default: 0
  enum :stage, {
    client_acquisition_project_qualification: 0,  # Initial client qualification
    client_invoiced: 1,                           # Client has been invoiced
    invoice_paid: 2,                              # Payment received
    preparing_for_kick_off_aml_resourcing: 3,    # Project preparation phase
    kicked_off_in_progress: 4,                    # Active project work
    submitted: 5,                                 # Application submitted to funder
    awaiting_funding_decision: 6,                 # Waiting for funding decision
    application_successful_or_not_successful: 7,  # Decision received
    resub_due: 8,                                 # Resubmission required
    success_fee_invoiced: 9,                      # Success fee invoiced
    success_fee_paid: 10                          # Success fee collected
  }, prefix: true
  
  validates :title, presence: true, length: { minimum: 3, maximum: 255 }
  validates :description, presence: true, length: { minimum: 10 }
  
  # Scopes
  scope :upcoming_deadlines, -> { joins(:grant_competition).where('grant_competitions.deadline > ?', Time.current).order('grant_competitions.deadline') }
  scope :overdue, -> { joins(:grant_competition).where('grant_competitions.deadline < ?', Time.current) }
  
  # Search scope
  scope :search_by_content, ->(query) {
    where("title LIKE ? OR description LIKE ?", "%#{query}%", "%#{query}%")
  }
  
  # Service delegations for extracted functionality
  def stage_service
    @stage_service ||= GrantApplicationStageService.new(self)
  end
  
  def workflow_service
    @workflow_service ||= GrantApplicationWorkflowService.new(self)
  end
  
  def validation_service
    @validation_service ||= GrantApplicationValidationService.new(self)
  end
  
  # Convenience methods that delegate to services
  def overdue?
    grant_competition&.deadline && grant_competition.deadline < Time.current
  end
  
  def days_until_deadline
    return nil if grant_competition&.deadline.nil?
    (grant_competition.deadline.to_date - Date.current).to_i
  end
  
  def humanize_stage
    stage.humanize
  end
  
  def can_edit?
    workflow_service.can_edit?
  end
  
  def can_submit?
    workflow_service.can_submit?
  end
  
  # Stage conflict detection methods (delegated to services)
  def automatic_stage
    stage_service.automatic_stage
  end
  
  def stage_conflict?
    stage_service.stage_conflict?
  end
  
  def stage_conflict_message
    stage_service.stage_conflict_message
  end
  
  def stage_conflict_details
    stage_service.stage_conflict_details
  end
end
