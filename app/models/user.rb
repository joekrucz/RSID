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
  
  # Role enum with explicit type
  attribute :role, :integer, default: 0
  enum :role, { client: 0, employee: 1, admin: 2 }
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { minimum: 2 }
  validates :password, length: { minimum: 6 }, if: -> { password.present? }
  validates :role, presence: true
  
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
end
