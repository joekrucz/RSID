# GrantApplicationWorkflowService
# 
# Handles business rules and workflow logic for grant applications.
# Extracted from GrantApplication model to follow Single Responsibility Principle.
class GrantApplicationWorkflowService
  def initialize(grant_application)
    @grant_application = grant_application
  end
  
  def can_edit?
    # Business rule: Can edit if not in final stages
    final_stages = ['success_fee_invoiced', 'success_fee_paid']
    !final_stages.include?(@grant_application.stage)
  end
  
  def can_submit?
    # Business rule: Can submit if all required sections are complete
    return false unless @grant_application.grant_checklist_items.any?
    
    required_sections = [
      'Client Acquisition/Project Qualification',
      'Client Invoiced',
      'Invoice Paid',
      'Preparing for Kick Off/AML/Resourcing',
      'Kicked Off/In Progress'
    ]
    
    required_sections.all? do |section|
      items = @grant_application.grant_checklist_items.where(section: section)
      items.any? && items.all?(&:checked)
    end
  end
  
  def can_change_stage?
    # Business rule: Can change stage if user has permission
    # This would typically check user roles and permissions
    true # Simplified for now
  end
  
  def next_stage
    return nil unless can_change_stage?
    
    current_idx = GrantApplication.stages[@grant_application.stage]
    next_idx = current_idx + 1
    
    return nil if next_idx >= GrantApplication.stages.size
    GrantApplication.stages.keys[next_idx]
  end
  
  def previous_stage
    return nil unless can_change_stage?
    
    current_idx = GrantApplication.stages[@grant_application.stage]
    prev_idx = current_idx - 1
    
    return nil if prev_idx < 0
    GrantApplication.stages.keys[prev_idx]
  end
  
  def stage_progress_percentage
    return 0 if @grant_application.grant_checklist_items.empty?
    
    total_items = @grant_application.grant_checklist_items.count
    completed_items = @grant_application.grant_checklist_items.where(checked: true).count
    
    (completed_items.to_f / total_items * 100).round(1)
  end
  
  def estimated_completion_date
    return nil unless @grant_application.grant_competition&.deadline
    
    # Simple estimation based on current progress
    progress = stage_progress_percentage / 100.0
    remaining_days = (@grant_application.grant_competition.deadline - Date.current).to_i
    
    if progress > 0
      estimated_days = remaining_days / progress
      Date.current + estimated_days.days
    else
      @grant_application.grant_competition.deadline
    end
  end
  
  def workflow_status
    if stage_conflict?
      :conflict
    elsif overdue?
      :overdue
    elsif can_submit?
      :ready_for_submission
    elsif stage_progress_percentage > 80
      :nearly_complete
    elsif stage_progress_percentage > 50
      :in_progress
    else
      :just_started
    end
  end
  
  private
  
  def stage_conflict?
    GrantApplicationStageService.new(@grant_application).stage_conflict?
  end
  
  def overdue?
    @grant_application.grant_competition&.deadline && 
    @grant_application.grant_competition.deadline < Time.current
  end
end
