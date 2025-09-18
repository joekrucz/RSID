class GrantChecklistItemsController < ApplicationController
  before_action :require_login
  before_action :set_grant_application

  # Upsert a checklist item for a grant application by section + title
  def upsert
    section = params[:section]
    title = params[:title]
    attrs = {
      due_date: params[:due_date],
      checked: params[:checked],
      technical_qualifier: params[:technical_qualifier],
      no_technical_qualifier: params[:no_technical_qualifier],
      contract_link: params[:contract_link],
      notes: params[:notes],
      deal_outcome: params[:deal_outcome],
      review_delivered_on: params[:review_delivered_on]
    }.compact

    item = @grant_application.grant_checklist_items.find_or_initialize_by(section: section, title: title)
    prev_checked = item.checked
    item.assign_attributes(attrs)
    if attrs.key?(:checked)
      if ActiveModel::Type::Boolean.new.cast(item.checked) && !prev_checked
        item.completed_at = Time.current
      elsif !ActiveModel::Type::Boolean.new.cast(item.checked) && prev_checked
        item.completed_at = nil
      end
    end

    if item.save
      # Recompute stage based on completed sections
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
        
        if items.all? { |it| it.checked }
          last_complete_idx = idx
        else
          # Found an incomplete section - stop here
          break
        end
      end
      
      # Check for stage conflicts and handle accordingly
      conflict_warning = nil
      if last_complete_idx >= 0
        new_stage = stage_keys[last_complete_idx]
        if new_stage && @grant_application.stage != new_stage
          if @grant_application.manual_stage_override?
            # Manual override is active - show warning but don't change stage
            conflict_warning = "Checklist suggests stage '#{new_stage.humanize}' but stage is manually set to '#{@grant_application.stage.humanize}'"
          else
            # No manual override - update stage automatically
            @grant_application.update(stage: new_stage, manual_stage_override: false)
          end
        end
      end
      
      render json: {
        success: true,
        item: item.as_json,
        stage: @grant_application.stage,
        conflict_warning: conflict_warning,
        conflict_details: @grant_application.stage_conflict_details,
        manual_override: @grant_application.manual_stage_override?
      }, status: :ok
    else
      render json: { success: false, errors: item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_grant_application
    @grant_application = @current_user.grant_applications.find(params[:grant_application_id])
  end
end