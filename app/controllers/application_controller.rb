class ApplicationController < ActionController::Base
  before_action :set_current_user
  before_action :check_feature_access
  
  private
  
  def set_current_user
    if session[:user_id]
      @current_user = User.find_by(id: session[:user_id])
      Rails.logger.info "Current user = #{@current_user&.name}"
    else
      Rails.logger.info "Current user = "
    end
  end
  
  def logged_in?
    @current_user.present?
  end
  
  def require_login
    unless @current_user
      Rails.logger.info "require_login called - no current user"
      redirect_to login_path, alert: "Please log in to access this page."
      return
    end
    
    Rails.logger.info "require_login called - current_user: #{@current_user.name}"
    Rails.logger.info "User authorized: #{@current_user.name}"
  end
  
  def require_employee
    require_login
    unless @current_user&.employee?
      redirect_to root_path, alert: "Access denied. Employee privileges required."
    end
  end
  
  def require_admin
    require_login
    unless @current_user&.admin?
      redirect_to root_path, alert: "Access denied. Admin privileges required."
    end
  end
  
  def require_client_access(client)
    return true if @current_user&.admin?
    return true if @current_user&.employee? && client.employee == @current_user
    return true if @current_user&.client? && client.user == @current_user
    false
  end
  
  # Feature flag methods
  def check_feature_access
    return unless @current_user
    
    # Store available features in session for quick access
    session[:available_features] = @current_user.available_features.map(&:name)
  end
  
  def require_feature(feature_name)
    unless FeatureFlagService.enabled?(feature_name, @current_user)
      redirect_to dashboard_path, 
        alert: "This feature is not available for your account."
    end
  end
  
  def feature_enabled?(feature_name)
    FeatureFlagService.enabled?(feature_name, @current_user)
  end
  
  helper_method :feature_enabled?
  
  def user_props
    return nil unless @current_user
    
    {
      id: @current_user.id,
      name: @current_user.name,
      email: @current_user.email,
      role: @current_user.role,
      isEmployee: @current_user.employee?,
      isAdmin: @current_user.admin?,
      isClient: @current_user.client?,
      canManageClients: @current_user.can_manage_clients?,
      canAccessGrantPipeline: @current_user.can_access_grant_pipeline?,
      canViewInternalNotes: @current_user.can_view_internal_notes?,
      availableFeatures: @current_user.available_features.map(&:name)
    }
  end
end
