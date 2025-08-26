class FeatureFlag < ApplicationRecord
  has_many :user_feature_accesses, dependent: :destroy
  has_many :users, through: :user_feature_accesses
  
  validates :name, presence: true, uniqueness: true
  
  scope :enabled, -> { where(enabled: true) }
  
  def enabled_for_user?(user)
    return false unless enabled?
    
    # Check user-specific override
    user_access = user_feature_accesses.find_by(user: user)
    return user_access&.enabled? if user_access
    
    # Check role-based defaults
    case user.role
    when 'admin'
      true # Admins get everything
    when 'employee'
      settings['employee_enabled'] || false
    when 'client'
      settings['client_enabled'] || false
    else
      false
    end
  end
  
  def display_name
    name.humanize
  end
end
