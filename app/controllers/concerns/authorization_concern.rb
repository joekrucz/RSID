module AuthorizationConcern
  extend ActiveSupport::Concern

  private

  def can_view_project?(project)
    @current_user.admin? || 
    @current_user.employee? || 
    project.client_id == @current_user.id
  end

  def can_edit_project?(project)
    @current_user.admin? || 
    @current_user.employee? ||
    (@current_user.client? && project.client_id == @current_user.id)
  end

  def can_view_person?(person)
    @current_user.admin? || 
    @current_user.employee? || 
    person.id == @current_user.id
  end

  def can_edit_person?(person)
    @current_user.admin? || 
    (@current_user.employee? && person.client?) ||
    person.id == @current_user.id
  end

  def can_access_message?(message)
    @current_user.admin? ||
    message.sender == @current_user ||
    message.recipient == @current_user ||
    (@current_user.employee? && message.client&.employee == @current_user)
  end

  def get_available_clients
    if @current_user.admin?
      User.clients.ordered_by_name
    elsif @current_user.employee?
      User.clients.ordered_by_name
    else
      # Clients can only see themselves
      User.where(id: @current_user.id).ordered_by_name
    end
  end

  def require_feature_access(feature_name)
    unless FeatureFlagService.enabled?(feature_name, @current_user)
      redirect_to dashboard_path, 
        alert: "This feature is not available for your account."
    end
  end
end
