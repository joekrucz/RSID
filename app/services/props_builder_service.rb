class PropsBuilderService
  def self.user_props(user)
    return nil unless user
    
    {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      isEmployee: user.employee?,
      isAdmin: user.admin?,
      isClient: user.client?,
      canManageClients: user.can_manage_clients?,
      canAccessGrantPipeline: user.can_access_grant_pipeline?,
      availableFeatures: []
    }
  end

  def self.rnd_claim_props(claim)
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
      cnf_status: claim.cnf_status,
      cnf_status_display: claim.cnf_status_display,
      cnf_status_badge_class: claim.cnf_status_badge_class,
      cnf_deadline: claim.cnf_deadline&.strftime("%Y-%m-%d"),
      cnf_deadline_overdue: claim.cnf_deadline_overdue?,
      cnf_deadline_due_soon: claim.cnf_deadline_due_soon?,
      cnf_emails: claim.cnf_emails.map { |email| cnf_email_props(email) },
      created_at: claim.created_at.strftime("%B %d, %Y"),
      updated_at: claim.updated_at.strftime("%B %d, %Y")
    }
  end

  def self.cnf_email_props(email)
    {
      id: email.id,
      email_slot: email.email_slot,
      template_type: email.template_type,
      status: email.status,
      status_display: email.status_display,
      status_badge_class: email.status_badge_class,
      icon_display: email.icon_display,
      sent_at: email.sent_at&.strftime("%Y-%m-%d %H:%M"),
      subject: email.subject,
      body: email.body,
      recipient_email: email.recipient_email,
      sender_email: email.sender_email
    }
  end




  def self.grant_application_props(application)
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

  private

  def self.format_date(date)
    return "N/A" if date.nil?
    date.strftime("%B %d, %Y")
  end

  def self.format_due_date(date)
    return "No due date" unless date
    date.strftime("%B %d, %Y")
  end

  def self.format_file_size(bytes)
    return "0 Bytes" if bytes.nil? || bytes == 0
    k = 1024
    sizes = ['Bytes', 'KB', 'MB', 'GB']
    i = Math.log(bytes) / Math.log(k)
    "#{sprintf('%.1f', bytes / k**i)} #{sizes[i.floor]}"
  end
end
