# GrantApplicationStageManagementService
# 
# Handles stage changes and validation for grant applications.
# Extracted from GrantApplicationsController to follow Single Responsibility Principle.
class GrantApplicationStageManagementService
  def initialize(grant_application)
    @grant_application = grant_application
  end

  def change_stage(new_stage)
    return error_result("Invalid stage") unless GrantApplication.stages.key?(new_stage)
    
    if @grant_application.update(stage: new_stage, manual_stage_override: true)
      success_result(new_stage)
    else
      error_result(@grant_application.errors.full_messages.join(', '))
    end
  end

  private

  def success_result(stage)
    {
      success: true,
      message: "Stage updated to #{stage.humanize}!",
      stage: stage,
      manual_override: true,
      conflict_warning: @grant_application.stage_conflict_message,
      conflict_details: @grant_application.stage_conflict_details
    }
  end

  def error_result(message)
    {
      success: false,
      message: message
    }
  end
end
