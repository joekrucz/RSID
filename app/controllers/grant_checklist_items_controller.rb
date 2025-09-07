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

