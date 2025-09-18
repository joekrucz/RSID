# UserSearchService
# 
# Handles all user search and filtering logic.
# Extracted from User model to follow Single Responsibility Principle.
class UserSearchService
  def initialize(current_user)
    @current_user = current_user
  end
  
  def search_by_name_or_email(query)
    return User.none if query.blank?
    
    sanitized_query = SanitizationService.sanitize_search_term(query)
    return User.none if sanitized_query.blank?
    
    User.where("name LIKE ? OR email LIKE ?", "%#{sanitized_query}%", "%#{sanitized_query}%")
  end
  
  def filtered_and_sorted(search: nil, role_filter: nil, sort_by: 'name', sort_order: 'ASC')
    users = accessible_users
    
    users = users.search_by_name_or_email(search) if search.present?
    users = users.by_role(role_filter) if role_filter.present?
    users.sorted_by(sort_by, sort_order)
  end
  
  def search_global(query)
    accessible_users.search_by_name_or_email(query)
  end
  
  private
  
  def accessible_users
    if @current_user.admin?
      User.all
    elsif @current_user.employee?
      User.all
    else
      User.where(id: @current_user.id) # Clients can only see themselves
    end
  end
end
