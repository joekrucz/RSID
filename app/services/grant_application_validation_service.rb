# GrantApplicationValidationService
# 
# Handles validation logic for grant applications.
# Extracted from GrantApplication model to follow Single Responsibility Principle.
class GrantApplicationValidationService
  def initialize(grant_application)
    @grant_application = grant_application
  end
  
  def validate_for_submission
    errors = []
    
    # Check required fields
    errors << "Title is required" if @grant_application.title.blank?
    errors << "Description is required" if @grant_application.description.blank?
    errors << "Company must be selected" if @grant_application.company.blank?
    errors << "Grant competition must be selected" if @grant_application.grant_competition.blank?
    
    # Check business rules
    errors << "Cannot submit without completing required sections" unless can_submit?
    errors << "Application is overdue" if overdue?
    errors << "Stage conflict must be resolved" if stage_conflict?
    
    # Check checklist items
    errors.concat(checklist_validation_errors)
    
    errors
  end
  
  def validate_stage_change(new_stage)
    errors = []
    
    # Check if stage change is allowed
    unless can_change_stage?
      errors << "Stage change not allowed"
      return errors
    end
    
    # Check if new stage is valid
    unless GrantApplication.stages.key?(new_stage)
      errors << "Invalid stage: #{new_stage}"
      return errors
    end
    
    # Check business rules for specific stage changes
    current_idx = GrantApplication.stages[@grant_application.stage]
    new_idx = GrantApplication.stages[new_stage]
    
    if new_idx < current_idx
      errors << "Cannot move to earlier stage"
    end
    
    if new_idx > current_idx + 1
      errors << "Cannot skip stages"
    end
    
    errors
  end
  
  def validate_checklist_item(item)
    errors = []
    
    # Check required fields
    errors << "Title is required" if item.title.blank?
    errors << "Section is required" if item.section.blank?
    
    # Check business rules
    if item.due_date && item.due_date < Date.current
      errors << "Due date cannot be in the past"
    end
    
    if item.checked && item.completed_at.blank?
      errors << "Completed date is required when item is checked"
    end
    
    errors
  end
  
  private
  
  def can_submit?
    GrantApplicationWorkflowService.new(@grant_application).can_submit?
  end
  
  def can_change_stage?
    GrantApplicationWorkflowService.new(@grant_application).can_change_stage?
  end
  
  def overdue?
    @grant_application.grant_competition&.deadline && 
    @grant_application.grant_competition.deadline < Time.current
  end
  
  def stage_conflict?
    GrantApplicationStageService.new(@grant_application).stage_conflict?
  end
  
  def checklist_validation_errors
    errors = []
    
    # Check that all required sections have items
    required_sections = [
      'Client Acquisition/Project Qualification',
      'Client Invoiced',
      'Invoice Paid'
    ]
    
    required_sections.each do |section|
      items = @grant_application.grant_checklist_items.where(section: section)
      if items.empty?
        errors << "Section '#{section}' must have at least one checklist item"
      end
    end
    
    errors
  end
end
