class FeatureFlagService
  def self.enabled?(feature_name, user)
    return true if user.admin? # Admins bypass all flags
    
    feature_flag = FeatureFlag.find_by(name: feature_name)
    return false unless feature_flag
    
    feature_flag.enabled_for_user?(user)
  end
  
  def self.available_features_for_user(user)
    FeatureFlag.enabled.select { |flag| enabled?(flag.name, user) }
  end
  
  def self.update_user_access(user, feature_name, enabled, settings = {})
    feature_flag = FeatureFlag.find_by(name: feature_name)
    return false unless feature_flag
    
    user_access = UserFeatureAccess.find_or_initialize_by(
      user: user, 
      feature_flag: feature_flag
    )
    
    user_access.enabled = enabled
    user_access.settings = settings
    user_access.save
  end
  
  def self.get_user_access(user, feature_flag)
    UserFeatureAccess.find_by(user: user, feature_flag: feature_flag)
  end
end
