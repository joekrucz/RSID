class User < ApplicationRecord
  has_secure_password
  
  # Role-based associations
  has_many :notes, dependent: :destroy
  has_many :todos, dependent: :destroy
  has_many :file_items, dependent: :destroy
  has_many :clients, dependent: :destroy
  
  # Employee-specific associations
  has_many :assigned_clients, class_name: 'Client', foreign_key: 'employee_id', dependent: :destroy
  
  # Client-specific associations (when user is a client)
  has_one :client_profile, class_name: 'Client', foreign_key: 'user_id', dependent: :destroy
  
           # Message associations
         has_many :sent_messages, class_name: 'Message', foreign_key: 'sender_id', dependent: :destroy
         has_many :received_messages, class_name: 'Message', foreign_key: 'recipient_id', dependent: :destroy
         
         # Grant Application associations
         has_many :grant_applications, dependent: :destroy
         
         # R&D Project associations
         has_many :rnd_projects, dependent: :destroy
         
         # Feature flag associations
         has_many :user_feature_accesses, dependent: :destroy
         has_many :feature_flags, through: :user_feature_accesses
         
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
    where("name LIKE ? OR email LIKE ?", "%#{query}%", "%#{query}%")
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
  
  # Role-based helper methods
  def employee?
    role == 'employee' || role == 'admin'
  end
  
  def admin?
    role == 'admin'
  end
  
  def client?
    role == 'client'
  end
  
  def can_manage_clients?
    employee?
  end
  
  def can_access_grant_pipeline?
    employee?
  end
  
  def can_view_internal_notes?
    employee?
  end
  
  # Feature flag methods
  def feature_enabled?(feature_name)
    feature_flag = FeatureFlag.find_by(name: feature_name)
    return false unless feature_flag
    
    feature_flag.enabled_for_user?(self)
  end
  
  def available_features
    FeatureFlag.enabled.select { |flag| feature_enabled?(flag.name) }
  end
  
  # Get accessible clients based on role
  def accessible_clients
    if admin?
      Client.all
    elsif employee?
      assigned_clients
    elsif client?
      [client_profile].compact
    else
      Client.none
    end
  end
  
  # Get accessible messages based on role
  def accessible_messages
    if admin?
      Message.all
    elsif employee?
      Message.where(sender: self).or(Message.where(recipient: self))
    elsif client?
      client_profile ? Message.for_client(client_profile) : Message.none
    else
      Message.none
    end
  end
  
  # Class method for complex filtering and sorting
  def self.filtered_and_sorted(current_user, search: nil, role_filter: nil, sort_by: 'name', sort_order: 'ASC')
    people = if current_user.admin?
               all
             elsif current_user.employee?
               all
             else
               where(id: current_user.id) # Clients can only see themselves
             end
    
    people = people.search_by_name_or_email(search) if search.present?
    people = people.by_role(role_filter) if role_filter.present?
    people.sorted_by(sort_by, sort_order)
  end
  
  # Global search method
  def self.search_global(query, current_user)
    base_query = if current_user.admin?
                   all
                 elsif current_user.employee?
                   all
                 else
                   where(id: current_user.id)
                 end
    
    base_query.search_by_name_or_email(query)
  end
end
