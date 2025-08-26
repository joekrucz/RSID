class RndExpendituresController < ApplicationController
  before_action :require_login
  before_action :require_employee
  before_action :set_rnd_project
  before_action :set_rnd_expenditure, only: [:edit, :update, :destroy]

  def create
    @expenditure = @rnd_project.rnd_expenditures.build(rnd_expenditure_params)
    
    if @expenditure.save
      redirect_to rnd_project_path(@rnd_project), notice: "Expenditure added successfully!"
    else
      redirect_to rnd_project_path(@rnd_project), alert: "Failed to add expenditure: #{@expenditure.errors.full_messages.join(', ')}"
    end
  end

  def edit
    render inertia: 'RndExpenditures/Edit', props: {
      user: user_props,
      rnd_project: rnd_project_props(@rnd_project),
      rnd_expenditure: rnd_expenditure_props(@expenditure)
    }
  end

  def update
    if @expenditure.update(rnd_expenditure_params)
      redirect_to rnd_project_path(@rnd_project), notice: "Expenditure updated successfully!"
    else
      render inertia: 'RndExpenditures/Edit', props: {
        user: user_props,
        rnd_project: rnd_project_props(@rnd_project),
        rnd_expenditure: rnd_expenditure_props(@expenditure),
        errors: @expenditure.errors.full_messages
      }
    end
  end

  def destroy
    if @expenditure.destroy
      redirect_to rnd_project_path(@rnd_project), notice: "Expenditure deleted successfully!"
    else
      redirect_to rnd_project_path(@rnd_project), alert: "Failed to delete expenditure."
    end
  end

  private

  def set_rnd_project
    @rnd_project = RndProject.find(params[:rnd_project_id])
  end

  def set_rnd_expenditure
    @expenditure = @rnd_project.rnd_expenditures.find(params[:id])
  end

  def rnd_expenditure_params
    params.require(:rnd_expenditure).permit(:expenditure_type, :amount, :description, :date)
  end

  def rnd_project_props(project)
    {
      id: project.id,
      title: project.title,
      description: project.description,
      client: {
        id: project.client.id,
        name: project.client.name,
        email: project.client.email
      },
      start_date: project.start_date&.strftime("%Y-%m-%d"),
      end_date: project.end_date&.strftime("%Y-%m-%d"),
      status: project.status,
      total_expenditure: project.total_expenditure,
      created_at: project.created_at.strftime("%B %d, %Y")
    }
  end

  def rnd_expenditure_props(expenditure)
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