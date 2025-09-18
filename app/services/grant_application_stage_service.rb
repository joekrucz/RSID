# GrantApplicationStageService
# 
# Handles all stage calculation logic for grant applications.
# Extracted from GrantApplication model to follow Single Responsibility Principle.
class GrantApplicationStageService
  def initialize(grant_application)
    @grant_application = grant_application
  end
  
  def automatic_stage
    return nil if @grant_application.grant_checklist_items.empty?
    
    items_by_section = @grant_application.grant_checklist_items.group_by(&:section)
    last_complete_idx = -1
    
    # Check each section in order - ALL prior sections must be complete
    frontend_section_order.each_with_index do |frontend_sec, idx|
      backend_sec = section_mapping[frontend_sec]
      items = items_by_section[backend_sec] || []
      
      # If no items exist for this section, we can't determine completion
      if items.empty?
        break
      end
      
      if items.all?(&:checked)
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
    auto_stage = automatic_stage
    return false unless auto_stage
    auto_stage != @grant_application.stage
  end
  
  def stage_conflict_message
    return nil unless stage_conflict?
    auto_stage = automatic_stage
    return nil unless auto_stage
    
    if @grant_application.manual_stage_override?
      "Stage manually set to '#{@grant_application.stage.humanize}' but checklist suggests '#{auto_stage.humanize}'"
    else
      "Stage is '#{@grant_application.stage.humanize}' but checklist suggests '#{auto_stage.humanize}'"
    end
  end
  
  def stage_conflict_details
    return nil unless stage_conflict?
    auto_stage = automatic_stage
    return nil unless auto_stage
    
    current_stage_idx = GrantApplication.stages[@grant_application.stage]
    auto_stage_idx = GrantApplication.stages[auto_stage]
    
    items_by_section = @grant_application.grant_checklist_items.group_by(&:section)
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
              section: frontend_sec,
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
              section: frontend_sec,
              title: item.title,
              message: "Untick '#{item.title}' in #{frontend_sec}"
            }
          end
        end
      end
    end
    
    required_changes
  end
  
  private
  
  def section_mapping
    {
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
  end
  
  def frontend_section_order
    [
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
  end
  
  def stage_keys
    GrantApplication.stages.keys
  end
end
