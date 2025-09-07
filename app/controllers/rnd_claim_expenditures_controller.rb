class RndClaimExpendituresController < ApplicationController
  before_action :require_login
  before_action :require_employee
  before_action :set_rnd_claim
  before_action :set_rnd_claim_expenditure, only: [:edit, :update, :destroy]

  def create
    @expenditure = @rnd_claim.rnd_claim_expenditures.build(rnd_claim_expenditure_params)
    
    if @expenditure.save
      redirect_to rnd_claim_path(@rnd_claim), notice: "Expenditure added successfully!"
    else
      redirect_to rnd_claim_path(@rnd_claim), alert: "Failed to add expenditure: #{@expenditure.errors.full_messages.join(', ')}"
    end
  end

  def edit
    render inertia: 'RndClaimExpenditures/Edit', props: {
      user: user_props,
      rnd_claim: rnd_claim_props(@rnd_claim),
      rnd_claim_expenditure: rnd_claim_expenditure_props(@expenditure)
    }
  end

  def update
    if @expenditure.update(rnd_claim_expenditure_params)
      redirect_to rnd_claim_path(@rnd_claim), notice: "Expenditure updated successfully!"
    else
      render inertia: 'RndClaimExpenditures/Edit', props: {
        user: user_props,
        rnd_claim: rnd_claim_props(@rnd_claim),
        rnd_claim_expenditure: rnd_claim_expenditure_props(@expenditure),
        errors: @expenditure.errors.full_messages
      }
    end
  end

  def destroy
    if @expenditure.destroy
      redirect_to rnd_claim_path(@rnd_claim), notice: "Expenditure deleted successfully!"
    else
      redirect_to rnd_claim_path(@rnd_claim), alert: "Failed to delete expenditure."
    end
  end

  private

  def set_rnd_claim
    @rnd_claim = RndClaim.find(params[:rnd_claim_id])
  end

  def set_rnd_claim_expenditure
    @expenditure = @rnd_claim.rnd_claim_expenditures.find(params[:id])
  end

  def rnd_claim_expenditure_params
    params.require(:rnd_claim_expenditure).permit(:expenditure_type, :amount, :description, :date)
  end

  def rnd_claim_props(claim)
    {
      id: claim.id,
      title: claim.title,
      stage: claim.stage || 'upcoming',
      company: claim.company ? {
        id: claim.company.id,
        name: claim.company.name
      } : nil,
      start_date: claim.start_date&.strftime("%Y-%m-%d"),
      end_date: claim.end_date&.strftime("%Y-%m-%d"),
      qualifying_activities: claim.qualifying_activities,
      technical_challenges: claim.technical_challenges,
      total_expenditure: claim.total_expenditure,
      expenditure_by_type: claim.expenditure_by_type,
      duration_days: claim.duration_days,
      is_active: claim.is_active?,
      can_be_claimed: claim.can_be_claimed?,
      created_at: claim.created_at.strftime("%B %d, %Y"),
      updated_at: claim.updated_at.strftime("%B %d, %Y")
    }
  end

  def rnd_claim_expenditure_props(expenditure)
    {
      id: expenditure.id,
      expenditure_type: expenditure.expenditure_type,
      amount: expenditure.amount,
      description: expenditure.description,
      date: expenditure.date&.strftime("%Y-%m-%d"),
      qualifying_amount: expenditure.qualifying_amount,
      is_qualifying: expenditure.is_qualifying?,
      formatted_amount: expenditure.formatted_amount,
      formatted_qualifying_amount: expenditure.formatted_qualifying_amount,
      created_at: expenditure.created_at.strftime("%B %d, %Y")
    }
  end
end 