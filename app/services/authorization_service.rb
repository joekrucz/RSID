# AuthorizationService
# 
# Handles all authorization logic for users.
# Extracted from User model to follow Single Responsibility Principle.
class AuthorizationService
  def initialize(user)
    @user = user
  end
  
  # Role checks
  def employee?
    @user.role == 'employee' || @user.role == 'admin'
  end
  
  def admin?
    @user.role == 'admin'
  end
  
  def client?
    @user.role == 'client'
  end
  
  # Permission checks
  def can_manage_clients?
    employee?
  end
  
  def can_access_grant_pipeline?
    employee?
  end
  
  def can_view_person?(person)
    admin? || employee? || person.id == @user.id
  end
  
  def can_edit_person?(person)
    admin? || (employee? && person.client?) || person.id == @user.id
  end
  
  def can_view_project?(project)
    admin? || employee? || project.client_id == @user.id
  end
  
  def can_edit_project?(project)
    admin? || employee? || (client? && project.client_id == @user.id)
  end
  
  # Accessible data based on role
  def accessible_clients
    if admin?
      Client.all
    elsif employee?
      @user.assigned_clients
    elsif client?
      [@user.client_profile].compact
    else
      Client.none
    end
  end
  
  def accessible_users
    if admin?
      User.all
    elsif employee?
      User.all
    else
      User.where(id: @user.id) # Clients can only see themselves
    end
  end
end
