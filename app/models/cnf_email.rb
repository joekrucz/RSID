class CnfEmail < ApplicationRecord
  belongs_to :rnd_claim
  
  # Validations
  validates :email_slot, presence: true, inclusion: { in: %w[1 2 3 4 5 6 FS] }
  validates :template_type, presence: true, inclusion: { in: %w[initial monthly urgent] }
  validates :status, presence: true, inclusion: { in: %w[sent to_be_sent skipped to_be_skipped] }
  validates :email_slot, uniqueness: { scope: :rnd_claim_id }
  
  # Scopes
  scope :sent, -> { where(status: 'sent') }
  scope :to_be_sent, -> { where(status: 'to_be_sent') }
  scope :skipped, -> { where(status: 'skipped') }
  scope :to_be_skipped, -> { where(status: 'to_be_skipped') }
  scope :by_slot, ->(slot) { where(email_slot: slot) }
  scope :by_template, ->(template) { where(template_type: template) }
  
  # Helper methods
  def sent?
    status == 'sent'
  end
  
  def to_be_sent?
    status == 'to_be_sent'
  end
  
  def skipped?
    status == 'skipped'
  end
  
  def to_be_skipped?
    status == 'to_be_skipped'
  end
  
  def status_display
    case status
    when 'sent' then 'SENT'
    when 'to_be_sent' then 'TO BE SENT'
    when 'skipped' then 'SKIPPED'
    when 'to_be_skipped' then 'TO BE SKIPPED'
    else status.humanize.upcase
    end
  end
  
  def status_badge_class
    case status
    when 'sent' then 'badge-success'
    when 'to_be_sent' then 'badge-info'
    when 'skipped' then 'badge-warning'
    when 'to_be_skipped' then 'badge-neutral'
    else 'badge-neutral'
    end
  end
  
  def icon_display
    case status
    when 'sent' then '✅'
    when 'to_be_sent' then '📤'
    when 'skipped' then '⏭️'
    when 'to_be_skipped' then '⏸️'
    else '📁'
    end
  end
  
  # Class methods
  def self.create_for_claim(claim, email_slot, template_type = nil)
    # Determine template type based on slot if not provided
    template_type ||= case email_slot
                     when '1' then 'initial'
                     when '2', '3', '4', '5' then 'monthly'
                     when '6', 'FS' then 'urgent'
                     else 'initial'
                     end
    
    find_or_create_by(rnd_claim: claim, email_slot: email_slot) do |email|
      email.template_type = template_type
      email.status = 'to_be_sent'
      email.recipient_email = generate_recipient_email(claim)
      email.subject = generate_subject(claim, template_type)
      email.body = generate_body(claim, template_type)
    end
  end
  
  private
  
  def self.generate_recipient_email(claim)
    return 'client@company.com' unless claim.company&.name
    
    "#{claim.company.name.downcase.gsub(/\s+/, '')}@company.com"
  end
  
  def self.generate_subject(claim, template_type)
    fy = claim.end_date ? "FY#{claim.end_date.strftime('%y')}" : 'FY25'
    deadline = claim.end_date ? (claim.end_date + 6.months).strftime('%d/%m/%y') : 'TBD'
    
    case template_type
    when 'initial'
      "You are now in your CNF period for #{fy}"
    when 'monthly'
      "Reminder: You are in your CNF period for #{fy}"
    when 'urgent'
      "CNF DEADLINE REMINDER - due #{deadline}"
    else
      "CNF Communication for #{fy}"
    end
  end
  
  def self.generate_body(claim, template_type)
    fy = claim.end_date ? "FY#{claim.end_date.strftime('%y')}" : 'FY25'
    deadline = claim.end_date ? (claim.end_date + 6.months).strftime('%d/%m/%y') : 'TBD'
    
    case template_type
    when 'initial'
      generate_initial_body(fy)
    when 'monthly'
      generate_monthly_body(fy)
    when 'urgent'
      generate_urgent_body(deadline)
    else
      "Email content for #{template_type} template"
    end
  end
  
  def self.generate_initial_body(fy)
    "Hi,\n\nThis is an automated, but important message to let you know that you are now within the six-month window to notify HMRC of your intention to make an R&D Tax Credit claim for #{fy}.\n\nThe deadline to submit your CNF is 6 months after the end of the claim's accounting period - if you have extended or shortened your company's year-end, please be advised that will also impact the deadline for the CNF.\n\nAs part of recent changes to R&D legislation, HMRC now requires companies to submit a 'Claim Notification' to inform them that they intend to claim. This applies to all accounting periods starting on or after 1 April 2023.\n\nAction required\nTo make this process easy, GrantTree can of course submit the notification on your behalf, but we need a few key details from you first. Please complete the attached form to help us to do so. If the form is not submitted in time, HMRC will reject your claim, even if all other criteria are met.\n\nIgnore if…\nIf you're already in touch with us about this, feel free to ignore this message. Otherwise, if you have any questions or need help completing the form, please get in touch with a member of the GrantTree team and we will be happy to assist.\n\nBest regards,\n\nThe GrantTree Team"
  end
  
  def self.generate_monthly_body(fy)
    "Hi,\n\nThis is a reminder that you are currently within your Claim Notification Form (CNF) period for your #{fy} R&D Tax Credit claim.\n\nHMRC requires companies to notify them of their intention to claim R&D Tax Relief no later than 6 months after the end of the claim's accounting period. If your year-end has been extended or shortened, please note this will also affect your CNF deadline.\n\nAction required\nTo make this process simple, GrantTree can submit the CNF on your behalf. However, we first need a few key details from you. Please complete the attached form as soon as possible so we can take care of the submission for you. If the CNF is not filed in time, HMRC will reject your claim—even if all other criteria are met.\n\nIgnore if… If you're already in touch with us about this, feel free to disregard this message. Otherwise, please get in touch with a member of the GrantTree team if you have any questions or need support completing the form.\n\nBest regards,\n\nThe GrantTree Team"
  end
  
  def self.generate_urgent_body(deadline)
    "Hi,\n\nThis is an urgent reminder that the deadline for submitting your R&D Claim Notification Form is #{deadline}.\n\nFailure to submit this form by the deadline will prevent you from claiming R&D Tax Relief for your previous accounting period.\n\nNext Steps:\n• If you intend to claim R&D tax relief, please submit the Claim Notification Form immediately.\n• If you believe you do not need to submit this form, please contact us immediately to confirm.\n• If you think another party, including GrantTree, has already handled this for you, or if you have any questions, please contact us immediately.\n• Currently, based on the information we hold, we cannot submit this form on your behalf; you will need to complete this action yourself.\n\nIf you have already submitted the notification form or instructed us to do so, thank you - no further action is needed.\n\nPlease reach out if you need any assistance.\n\nBest regards,\n\nThe GrantTree Team"
  end
end
