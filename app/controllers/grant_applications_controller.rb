# GrantApplicationsController
# 
# This controller handles grant application CRUD operations.
# Refactored to be thin and focused, following Rails conventions.
#
# Key responsibilities:
# - CRUD operations for grant applications
# - Delegates complex logic to services and presenters

require_relative '../presenters/grant_application_presenter'

class GrantApplicationsController < ApplicationController
  before_action :require_login
  before_action :set_grant_application, only: [:show, :edit, :update, :destroy, :change_stage]
  
  def index
    search_result = GrantApplicationSearchService.new(@current_user, params).call
    render inertia: 'GrantApplications/Index', 
           props: GrantApplicationPresenter.index_props(
             search_result[:applications], 
             @current_user, 
             search_result
           )
  end
  
  def show
    render inertia: 'GrantApplications/Show', 
           props: GrantApplicationPresenter.show_props(@grant_application, @current_user)
  end
  
  def new
    render inertia: 'GrantApplications/New', 
           props: GrantApplicationPresenter.new_props(@current_user)
  end
  
  def create
    @grant_application = @current_user.grant_applications.build(grant_application_params)
    
    if @grant_application.save
      redirect_to grant_applications_path, notice: 'Grant application created successfully!'
    else
      render inertia: 'GrantApplications/New', 
             props: GrantApplicationPresenter.new_props(@current_user, @grant_application)
    end
  end
  
  def edit
    render inertia: 'GrantApplications/Edit', 
           props: GrantApplicationPresenter.edit_props(@grant_application, @current_user)
  end
  
  def update
    if @grant_application.update(grant_application_params)
      redirect_to grant_applications_path, notice: 'Grant application updated successfully!'
    else
      render inertia: 'GrantApplications/Edit', 
             props: GrantApplicationPresenter.edit_props(@grant_application, @current_user)
    end
  end
  
  def destroy
    @grant_application.destroy
    redirect_to grant_applications_path, notice: 'Grant application deleted successfully!'
  end
  
  

  def change_stage
    result = GrantApplicationStageManagementService.new(@grant_application).change_stage(params[:stage])
    
    if result[:success]
      render json: result
    else
      render json: result, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_grant_application
    @grant_application = @current_user.grant_applications.find(params[:id])
  end
  
  
  def grant_application_params
    params.require(:grant_application).permit(:title, :description, :stage, :company_id, :grant_competition_id, :qualification_cost_pence)
  end
end 