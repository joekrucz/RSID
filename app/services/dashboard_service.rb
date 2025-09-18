# DashboardService
# 
# Handles all business logic for dashboard data gathering.
# Extracted from DashboardController to follow Rails conventions.
class DashboardService
  def initialize(user)
    @user = user
  end
  
  def call
    {
      user: PropsBuilderService.user_props(@user),
      stats: role_specific_stats,
      recent_activity: recent_activity
    }
  end
  
  private
  
  def role_specific_stats
    base_stats.merge(role_specific_additions)
  end
  
  def base_stats
    {
      grant_applications: @user.grant_applications.count,
      grant_applications_overdue: @user.grant_applications.overdue.count,
      rnd_claims: accessible_rnd_claims.count,
      rnd_claims_draft: accessible_rnd_claims.where(stage: 'upcoming').count,
      rnd_claims_ready_for_claim: accessible_rnd_claims.where(stage: 'finalised').count,
      rnd_claims_submitted: accessible_rnd_claims.where(stage: 'submitted').count,
      rnd_claims_approved: accessible_rnd_claims.where(stage: 'approved').count,
      rnd_claims_rejected: accessible_rnd_claims.where(stage: 'rejected').count,
      rnd_claims_paid: accessible_rnd_claims.where(stage: 'paid').count,
      notifications: @user.notifications.count,
      unread_notifications: @user.notifications.where(read: false).count
    }
  end
  
  def role_specific_additions
    case @user.role
    when 'admin'
      admin_stats
    when 'employee'
      employee_stats
    when 'client'
      client_stats
    else
      {}
    end
  end
  
  def admin_stats
    {
      total_users: User.count,
      total_companies: Company.count,
      total_grant_competitions: GrantCompetition.count,
      total_grant_applications: GrantApplication.count,
      total_rnd_claims: RndClaim.count
    }
  end
  
  def employee_stats
    {
      assigned_clients: @user.assigned_clients.count,
      total_companies: Company.count,
      total_grant_competitions: GrantCompetition.count
    }
  end
  
  def client_stats
    {
      client_profile: @user.client_profile ? client_props(@user.client_profile) : nil
    }
  end
  
  def recent_activity
    {
      grant_applications: @user.grant_applications.order(created_at: :desc).limit(3).map { |app| PropsBuilderService.grant_application_props(app) },
      rnd_claims: accessible_rnd_claims.order(created_at: :desc).limit(3).map { |claim| PropsBuilderService.rnd_claim_props(claim) }
    }
  end
  
  def accessible_rnd_claims
    if @user.admin?
      RndClaim.all
    elsif @user.employee?
      RndClaim.all
    elsif @user.client?
      @user.client_profile ? RndClaim.where(company: @user.client_profile) : RndClaim.none
    else
      RndClaim.none
    end
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
