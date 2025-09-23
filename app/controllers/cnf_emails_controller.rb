class CnfEmailsController < ApplicationController
  before_action :require_login

  def update
    @cnf_email = CnfEmail.find(params[:id])
    
    if @cnf_email.update(cnf_email_params)
      render json: { 
        success: true, 
        cnf_email: PropsBuilderService.cnf_email_props(@cnf_email) 
      }
    else
      render json: { 
        success: false, 
        errors: @cnf_email.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end

  def mark_as_sent
    @cnf_email = CnfEmail.find(params[:id])
    
    if @cnf_email.update(status: 'sent', sent_at: Time.current)
      render json: { 
        success: true, 
        cnf_email: PropsBuilderService.cnf_email_props(@cnf_email) 
      }
    else
      render json: { 
        success: false, 
        errors: @cnf_email.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end

  private

  def cnf_email_params
    params.require(:cnf_email).permit(:status, :subject, :body, :recipient_email, :sender_email)
  end
end
