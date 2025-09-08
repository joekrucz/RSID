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
      notes: params[:notes],
      subbie: params[:subbie],
      no_subbie: params[:no_subbie],
      contract_link: params[:contract_link]
    }.compact

    item = @grant_application.grant_checklist_items.find_or_initialize_by(section: section, title: title)
    item.assign_attributes(attrs)

    if item.save
      # Recompute stage based on completed sections
      section_order = [
        'Client Acquisition/Project Qualification',
        'Client Invoiced',
        'Invoice Paid',
        'Preparing for Kick Off/AML/Resourcing',
        'Kicked Off/In Progress',
        'Submitted',
        'Awaiting Funding Decision',
        'Application Successful/Not Successful',
        'Resub Due',
        'Success Fee Invoiced',
        'Success Fee Paid'
      ]
      stage_keys = GrantApplication.stages.keys
      items_by_section = @grant_application.grant_checklist_items.group_by(&:section)
      last_complete_idx = -1
      section_order.each_with_index do |sec, idx|
        items = items_by_section[sec] || []
        next if items.empty?
        if items.all? { |it| it.checked }
          last_complete_idx = idx
        else
          break
        end
      end
      if last_complete_idx >= 0
        new_stage = stage_keys[last_complete_idx]
        if new_stage && @grant_application.stage != new_stage
          @grant_application.update(stage: new_stage)
        end
      end

      render json: { success: true, item: item.as_json, stage: @grant_application.stage }, status: :ok
    else
      render json: { success: false, errors: item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_grant_application
    @grant_application = @current_user.grant_applications.find(params[:grant_application_id])
  end
end

class GrantChecklistItemsController < ApplicationController
  before_action :require_login
  before_action :set_grant_application

  def create
    item = @grant_application.grant_checklist_items.find_or_initialize_by(title: item_params[:title], section: item_params[:section])
    item.assign_attributes(item_params)
    if item.save
      head :ok
    else
      render json: { errors: item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    item = @grant_application.grant_checklist_items.find(params[:id])
    if item.update(item_params)
      head :ok
    else
      render json: { errors: item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_grant_application
    @grant_application = @current_user.grant_applications.find(params[:grant_application_id])
  end

  def item_params
    params.require(:grant_checklist_item).permit(:section, :title, :due_date, :checked, :notes, :subbie, :no_subbie, :contract_link)
  end
end

