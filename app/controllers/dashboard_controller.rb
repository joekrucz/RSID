class DashboardController < ApplicationController
  before_action :require_login

  def index
    
    # Get role-specific data
    role_data = get_role_specific_stats
    
    # Get recent activity
    recent_activity = get_recent_activity
    

    render inertia: 'Dashboard/Index', props: {
      user: user_props,
      stats: role_data,
      recent_activity: recent_activity
    }
  end

  private

  def get_role_specific_stats
    base_stats = {
      grant_applications: @current_user.grant_applications.count,
      grant_applications_overdue: @current_user.grant_applications.overdue.count,
      rnd_claims: get_accessible_rnd_claims.count,
      rnd_claims_draft: get_accessible_rnd_claims.where(stage: 'upcoming').count,
      rnd_claims_ready_for_claim: get_accessible_rnd_claims.where(stage: 'finalised').count,
      rnd_claims_submitted: get_accessible_rnd_claims.where(stage: 'submitted').count,
      rnd_claims_approved: get_accessible_rnd_claims.where(stage: 'approved').count,
      rnd_claims_rejected: get_accessible_rnd_claims.where(stage: 'rejected').count,
      rnd_claims_paid: get_accessible_rnd_claims.where(stage: 'paid').count,
      messages: get_accessible_messages.count,
      notifications: @current_user.notifications.count,
      unread_notifications: @current_user.notifications.where(read: false).count
    }

    # Add role-specific stats
    if @current_user.admin?
      base_stats.merge!({
        total_users: User.count,
        total_companies: Company.count,
        total_grant_competitions: GrantCompetition.count,
        total_grant_applications: GrantApplication.count,
        total_rnd_claims: RndClaim.count
      })
    elsif @current_user.employee?
      base_stats.merge!({
        assigned_clients: @current_user.assigned_clients.count,
        total_companies: Company.count,
        total_grant_competitions: GrantCompetition.count
      })
    elsif @current_user.client?
      base_stats.merge!({
        client_profile: @current_user.client_profile ? client_props(@current_user.client_profile) : nil
      })
    end

    base_stats
  end

  def get_recent_activity
    {
      grant_applications: @current_user.grant_applications.order(created_at: :desc).limit(3).map { |app| grant_application_props(app) },
      rnd_claims: get_accessible_rnd_claims.order(created_at: :desc).limit(3).map { |claim| rnd_claim_props(claim) },
      messages: get_accessible_messages.order(created_at: :desc).limit(3).map { |msg| message_props(msg) }
    }
  end


  def get_accessible_rnd_claims
    if @current_user.admin?
      RndClaim.all
    elsif @current_user.employee?
      RndClaim.all
    elsif @current_user.client?
      @current_user.client_profile ? RndClaim.where(company: @current_user.client_profile) : RndClaim.none
    else
      RndClaim.none
    end
  end

  def get_accessible_messages
    if @current_user.admin?
      Message.all
    elsif @current_user.employee?
      Message.where(sender: @current_user).or(Message.where(recipient: @current_user))
    elsif @current_user.client?
      @current_user.client_profile ? Message.for_client(@current_user.client_profile) : Message.none
    else
      Message.none
    end
  end

  def user_props
    {
      id: @current_user.id,
      name: @current_user.name,
      email: @current_user.email,
      role: @current_user.role,
      created_at: @current_user.created_at.strftime("%B %d, %Y")
    }
  end

  def grant_application_props(application)
    {
      id: application.id,
      title: application.title,
      description: application.description,
      stage: application.stage,
      deadline: format_date(application.grant_competition&.deadline),
      days_until_deadline: application.days_until_deadline,
      overdue: application.overdue?,
      created_at: format_date(application.created_at)
    }
  end

  def rnd_claim_props(claim)
    {
      id: claim.id,
      title: claim.title,
      stage: claim.stage,
      created_at: format_date(claim.created_at)
    }
  end

  def message_props(message)
    {
      id: message.id,
      subject: message.subject,
      sender: message.sender.name,
      created_at: format_date(message.created_at)
    }
  end

  def client_props(client)
    {
      id: client.id,
      name: client.name,
      email: client.email,
      created_at: format_date(client.created_at)
    }
  end

  def format_date(date)
    return nil unless date
    date.strftime("%B %d, %Y")
  end
end