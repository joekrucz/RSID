# ApplicationController
# 
# Base controller for the entire application.
# Handles common functionality like authentication, authorization, and feature flags.
# 
# Key responsibilities:
# - User session management
# - Feature flag access control
# - Authorization checks
# - User action logging
# - CSRF protection
class ApplicationController < ActionController::Base
  require_relative '../services/feature_flag_service'
  include ApplicationHelper
  include AuthorizationConcern
  include LoggingConcern
  # include PerformanceMonitoringConcern  # Temporarily disabled for debugging
  
  # Enable CSRF protection for all controllers
  protect_from_forgery with: :exception
  
  # Set up user context and feature access for every request
  before_action :set_current_user
  before_action :check_feature_access
  
  private
  
  def set_current_user
    if session[:user_id]
      @current_user = User.find_by(id: session[:user_id])
      log_user_action("session_start") if @current_user
    end
  end
  
  def logged_in?
    @current_user.present?
  end
  
  def require_login
    unless @current_user
      log_user_action("login_required_failed")
      # Store intended URL to support friendly forwarding after login
      begin
        if request.get?
          session[:forwarding_url] = request.fullpath
        end
      rescue StandardError
        # no-op
      end
      redirect_to login_sessions_path, alert: "Please log in to access this page."
      return
    end
    
    log_user_action("login_required_success")
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
    session[:available_features] = []
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
    PropsBuilderService.user_props(@current_user)
  end
end
