class GrantCompetitionsController < ApplicationController
  before_action :require_login
  before_action :set_grant_competition, only: [:show]

  def index
    @grant_competitions = GrantCompetition.all.order(:deadline)
    
    # Filter by status if requested
    if params[:status] == 'upcoming'
      @grant_competitions = @grant_competitions.upcoming
    elsif params[:status] == 'past'
      @grant_competitions = @grant_competitions.past
    end
    
    # Filter by funding body if requested
    if params[:funding_body].present?
      @grant_competitions = @grant_competitions.by_funding_body(params[:funding_body])
    end

    render inertia: 'GrantCompetitions/Index', props: {
      user: user_props,
      grant_competitions: @grant_competitions.map { |competition| grant_competition_props(competition) },
      filters: {
        status: params[:status],
        funding_body: params[:funding_body]
      },
      stats: {
        total: GrantCompetition.count,
        upcoming: GrantCompetition.upcoming.count,
        past: GrantCompetition.past.count
      }
    }
  end

  def show
    @grant_applications = @grant_competition.grant_applications.includes(:user, :company, :grant_documents)
                                          .order(created_at: :desc)

    render inertia: 'GrantCompetitions/Show', props: {
      user: user_props,
      grant_competition: grant_competition_props(@grant_competition),
      grant_applications: @grant_applications.map { |app| grant_application_props(app) }
    }
  end

  private

  def set_grant_competition
    @grant_competition = GrantCompetition.find(params[:id])
  end

  def grant_competition_props(competition)
    {
      id: competition.id,
      grant_name: competition.grant_name,
      deadline: competition.deadline,
      funding_body: competition.funding_body,
      competition_link: competition.competition_link,
      status: competition.status,
      upcoming: competition.upcoming?,
      past: competition.past?,
      days_until_deadline: competition.days_until_deadline,
      created_at: competition.created_at,
      updated_at: competition.updated_at
    }
  end

  def grant_application_props(application)
    {
      id: application.id,
      title: application.title,
      description: application.description,
      deadline: application.deadline,
      stage: application.stage,
      stage_human: application.humanize_stage,
      company: application.company ? {
        id: application.company.id,
        name: application.company.name
      } : nil,
      documents_count: application.grant_documents.count,
      created_at: application.created_at,
      updated_at: application.updated_at
    }
  end
end
