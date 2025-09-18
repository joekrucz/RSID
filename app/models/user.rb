# User Model
# 
# Handles user authentication and basic user data.
# Authorization, feature flags, and business logic have been extracted to services.
#
# Key responsibilities:
# - User authentication (has_secure_password)
# - Basic user data (name, email, role)
# - Core associations
class User < ApplicationRecord
  has_secure_password
  
  # Role-based associations
  # Users can manage multiple clients (for employees/admins)
  has_many :clients, dependent: :destroy
  
  # Employee-specific associations
  # When a user is an employee, they can be assigned to specific clients
  has_many :assigned_clients, class_name: 'Client', foreign_key: 'employee_id', dependent: :destroy
  
  # Client-specific associations (when user is a client)
  # When a user is a client, they have a single client profile
  has_one :client_profile, class_name: 'Client', foreign_key: 'user_id', dependent: :destroy
  
         
         # Grant Application associations
         has_many :grant_applications, dependent: :destroy
         
        # R&D Claim associations
        has_many :rnd_claims, dependent: :destroy
         
         
         # Notification associations
         has_many :notifications, dependent: :destroy
  
  # Role enum with explicit type
  attribute :role, :integer, default: 0
  enum :role, { client: 0, employee: 1, admin: 2 }
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { minimum: 2 }
  validates :password, length: { minimum: 6 }, if: -> { password.present? }
  validates :role, presence: true
  
  # Scopes
  scope :by_role, ->(role) { where(role: role) }
  scope :clients, -> { where(role: 'client') }
  scope :employees, -> { where(role: 'employee') }
  scope :admins, -> { where(role: 'admin') }
  scope :ordered_by_name, -> { order(:name) }
  
  # Search scope
  scope :search_by_name_or_email, ->(query) {
    return none if query.blank?
    sanitized_query = SanitizationService.sanitize_search_term(query)
    return none if sanitized_query.blank?
    where("name LIKE ? OR email LIKE ?", "%#{sanitized_query}%", "%#{sanitized_query}%")
  }
  
  # Sort scope
  scope :sorted_by, ->(field, direction = 'ASC') {
    case field
    when 'name'
      order("name #{direction.upcase}")
    when 'email'
      order("email #{direction.upcase}")
    when 'role'
      order("role #{direction.upcase}")
    when 'created_at'
      order("created_at #{direction.upcase}")
    else
      order("name #{direction.upcase}")
    end
  }
  
  # Service delegations for extracted functionality
  def authorization
    @authorization ||= AuthorizationService.new(self)
  end
  
  # Convenience methods that delegate to services
  def employee?
    authorization.employee?
  end
  
  def admin?
    authorization.admin?
  end
  
  def client?
    authorization.client?
  end
  
  def can_manage_clients?
    authorization.can_manage_clients?
  end
  
  def can_access_grant_pipeline?
    authorization.can_access_grant_pipeline?
  end
  
  def accessible_clients
    authorization.accessible_clients
  end
  
  # Class methods that delegate to services
  def self.filtered_and_sorted(current_user, search: nil, role_filter: nil, sort_by: 'name', sort_order: 'ASC')
    UserSearchService.new(current_user).filtered_and_sorted(
      search: search, 
      role_filter: role_filter, 
      sort_by: sort_by, 
      sort_order: sort_order
    )
  end
  
  def self.search_global(query, current_user)
    UserSearchService.new(current_user).search_global(query)
  end
end
