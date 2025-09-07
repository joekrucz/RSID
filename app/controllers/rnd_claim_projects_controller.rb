class RndClaimProjectsController < ApplicationController
  before_action :set_rnd_claim
  before_action :set_rnd_claim_project, only: [:show, :edit, :update, :destroy]
  
  def index
    @rnd_claim_projects = @rnd_claim.rnd_claim_projects.order(:name)
  end
  
  def show
  end
  
  def new
    @rnd_claim_project = @rnd_claim.rnd_claim_projects.build
  end
  
  def create
    @rnd_claim_project = @rnd_claim.rnd_claim_projects.build(rnd_claim_project_params)
    
    if @rnd_claim_project.save
      redirect_to rnd_claim_path(@rnd_claim, tab: 'projects'), notice: 'Project was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @rnd_claim_project.update(rnd_claim_project_params)
      redirect_to rnd_claim_path(@rnd_claim, tab: 'projects'), notice: 'Project was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @rnd_claim_project.destroy
    redirect_to rnd_claim_path(@rnd_claim, tab: 'projects'), notice: 'Project was successfully deleted.'
  end
  
  private
  
  def set_rnd_claim
    @rnd_claim = RndClaim.find(params[:rnd_claim_id])
  end
  
  def set_rnd_claim_project
    @rnd_claim_project = @rnd_claim.rnd_claim_projects.find(params[:id])
  end
  
  def rnd_claim_project_params
    params.require(:rnd_claim_project).permit(:name, :qualification_status, :narrative_status)
  end
end
