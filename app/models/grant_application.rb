class GrantApplication < ApplicationRecord
  belongs_to :user
  belongs_to :company, optional: true
  belongs_to :grant_competition, optional: true
  has_many :grant_documents, dependent: :destroy
  has_many :grant_checklist_items, dependent: :destroy
  
  
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
  
  # Scopes
  scope :upcoming_deadlines, -> { joins(:grant_competition).where('grant_competitions.deadline > ?', Time.current).order('grant_competitions.deadline') }
  scope :overdue, -> { joins(:grant_competition).where('grant_competitions.deadline < ?', Time.current) }
  
  # Search scope
  scope :search_by_content, ->(query) {
    where("title LIKE ? OR description LIKE ?", "%#{query}%", "%#{query}%")
  }
  
  # Helper methods
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
    true
  end
  
  def can_submit?
    false
  end
  
  # Stage conflict detection methods
  def automatic_stage
    # Map frontend section names to backend section names
    section_mapping = {
      'Client Acquisition' => 'Client Acquisition/Project Qualification',
      'Client Invoiced' => 'Client Invoiced',
      'Invoice Paid' => 'Invoice Paid',
      'KO Prep' => 'Preparing for Kick Off/AML/Resourcing',
      'Kicked Off' => 'Kicked Off/In Progress',
      'Submitted' => 'Submitted',
      'Awaiting Funding Decision' => 'Awaiting Funding Decision',
      'Funding Decision' => 'Application Successful/Not Successful',
      'Resub Due' => 'Resub Due',
      'Success Fee Invoiced' => 'Success Fee Invoiced',
      'Success Fee Paid' => 'Success Fee Paid'
    }
    
    frontend_section_order = [
      'Client Acquisition',
      'Client Invoiced',
      'Invoice Paid',
      'KO Prep',
      'Kicked Off',
      'Submitted',
      'Awaiting Funding Decision',
      'Funding Decision',
      'Resub Due',
      'Success Fee Invoiced',
      'Success Fee Paid'
    ]
    
    stage_keys = GrantApplication.stages.keys
    items_by_section = grant_checklist_items.group_by(&:section)
    last_complete_idx = -1
    
    # Check each section in order - ALL prior sections must be complete
    frontend_section_order.each_with_index do |frontend_sec, idx|
      backend_sec = section_mapping[frontend_sec]
      items = items_by_section[backend_sec] || []
      
      # If no items exist for this section, we can't determine completion
      # This means we can't progress past this point
      if items.empty?
        break
      end
      
      if items.all? { |it| it.checked }
        last_complete_idx = idx
      else
        # Found an incomplete section - stop here
        break
      end
    end
    
    return nil if last_complete_idx < 0
    stage_keys[last_complete_idx]
  end
  
  def stage_conflict?
    # Check for conflicts regardless of how the stage was set
    # This will catch both manual overrides and automatic stage mismatches
    auto_stage = automatic_stage
    return false unless auto_stage
    auto_stage != stage
  end
  
  def stage_conflict_message
    return nil unless stage_conflict?
    auto_stage = automatic_stage
    return nil unless auto_stage
    
    if manual_stage_override?
      "Stage manually set to '#{stage.humanize}' but checklist suggests '#{auto_stage.humanize}'"
    else
      "Stage is '#{stage.humanize}' but checklist suggests '#{auto_stage.humanize}'"
    end
  end
  
  def stage_conflict_details
    return nil unless stage_conflict?
    auto_stage = automatic_stage
    return nil unless auto_stage
    
    # Map frontend section names to backend section names
    section_mapping = {
      'Client Acquisition' => 'Client Acquisition/Project Qualification',
      'Client Invoiced' => 'Client Invoiced',
      'Invoice Paid' => 'Invoice Paid',
      'KO Prep' => 'Preparing for Kick Off/AML/Resourcing',
      'Kicked Off' => 'Kicked Off/In Progress',
      'Submitted' => 'Submitted',
      'Awaiting Funding Decision' => 'Awaiting Funding Decision',
      'Funding Decision' => 'Application Successful/Not Successful',
      'Resub Due' => 'Resub Due',
      'Success Fee Invoiced' => 'Success Fee Invoiced',
      'Success Fee Paid' => 'Success Fee Paid'
    }
    
    frontend_section_order = [
      'Client Acquisition',
      'Client Invoiced',
      'Invoice Paid',
      'KO Prep',
      'Kicked Off',
      'Submitted',
      'Awaiting Funding Decision',
      'Funding Decision',
      'Resub Due',
      'Success Fee Invoiced',
      'Success Fee Paid'
    ]
    
    current_stage_idx = GrantApplication.stages[stage]
    auto_stage_idx = GrantApplication.stages[auto_stage]
    
    items_by_section = grant_checklist_items.group_by(&:section)
    required_changes = []
    
    if current_stage_idx > auto_stage_idx
      # Current stage is ahead of automatic stage - need to complete more items
      (auto_stage_idx + 1..current_stage_idx).each do |idx|
        frontend_sec = frontend_section_order[idx]
        backend_sec = section_mapping[frontend_sec]
        next unless backend_sec
        
        items = items_by_section[backend_sec] || []
        items.each do |item|
          unless item.checked
            required_changes << {
              action: 'tick',
              section: frontend_sec, # Use frontend section name for display
              title: item.title,
              message: "Tick '#{item.title}' in #{frontend_sec}"
            }
          end
        end
      end
    elsif current_stage_idx < auto_stage_idx
      # Current stage is behind automatic stage - need to untick some items
      (current_stage_idx + 1..auto_stage_idx).each do |idx|
        frontend_sec = frontend_section_order[idx]
        backend_sec = section_mapping[frontend_sec]
        next unless backend_sec
        
        items = items_by_section[backend_sec] || []
        items.each do |item|
          if item.checked
            required_changes << {
              action: 'untick',
              section: frontend_sec, # Use frontend section name for display
              title: item.title,
              message: "Untick '#{item.title}' in #{frontend_sec}"
            }
          end
        end
      end
    end
    
    required_changes
  end
end
