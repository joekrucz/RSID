class CompaniesController < ApplicationController
  before_action :require_login

  def index
    @companies = Company.order(:name)
    render inertia: 'Companies/Index', props: {
      user: user_props,
      companies: @companies.map { |c| company_props(c) }
    }
  end

  def new
    render inertia: 'Companies/New', props: { user: user_props }
  end

  def show
    company = Company.find(params[:id])
    grant_applications = company.grant_applications.includes(:user).order(created_at: :desc)
    
    render inertia: 'Companies/Show', props: {
      user: user_props,
      company: company_props(company),
      grant_applications: grant_applications.map { |app| grant_application_props(app) }
    }
  end

  def create
    company = Company.new(company_params)
    if company.save
      redirect_to companies_path, notice: 'Company created successfully!'
    else
      render inertia: 'Companies/New', props: { user: user_props, errors: company.errors, company: company_params }
    end
  end

  private

  def company_params
    params.require(:company).permit(:name, :website, :notes)
  end

  def company_props(company)
    {
      id: company.id,
      name: company.name,
      website: company.website,
      notes: company.notes,
      created_at: company.created_at.strftime('%B %d, %Y')
    }
  end
  
  def grant_application_props(application)
    {
      id: application.id,
      title: application.title,
      description: application.description,
      status: application.status,
      stage: application.stage,
      stage_badge_class: view_context.grant_stage_badge_class(application.stage),
      deadline: application.deadline&.strftime("%B %d, %Y at %I:%M %p"),
      days_until_deadline: application.days_until_deadline,
      overdue: application.overdue?,
      created_at: application.created_at.strftime("%B %d, %Y"),
      documents_count: application.grant_documents.count
    }
  end
end

