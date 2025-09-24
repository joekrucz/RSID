class RndChecklistItemsController < ApplicationController
  before_action :require_login
  before_action :set_rnd_claim

  def upsert
    @rnd_claim.rnd_checklist_items.find_or_initialize_by(
      section: params[:section],
      title: params[:title]
    ).update!(checklist_item_params)
    
    render json: { success: true }
  rescue => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end

  private

  def set_rnd_claim
    @rnd_claim = RndClaim.find(params[:rnd_claim_id])
  end

  def checklist_item_params
    params.permit(
      :due_date, :checked, :technical_qualifier, :no_technical_qualifier,
      :contract_link, :review_delivered_on, :invoice_sent_on, :invoice_paid_on,
      :resourced_subcontractor, :delivery_folder_link, :slack_channel_name,
      :resub_due, :eligibility_check_cost_pence, :deal_outcome, :notes
    )
  end
end
