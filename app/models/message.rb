class Message < ApplicationRecord
  belongs_to :client
  belongs_to :sender, class_name: 'User'
  belongs_to :recipient, class_name: 'User'
  
  # Message type enum with explicit type
  attribute :message_type, :integer, default: 0
  enum :message_type, { internal: 0, client_communication: 1 }
  
  validates :subject, presence: true, length: { minimum: 3, maximum: 200 }
  validates :content, presence: true, length: { minimum: 10 }
  validates :client, presence: true
  validates :sender, presence: true
  validates :recipient, presence: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :between_users, ->(user1, user2) { where(sender: [user1, user2], recipient: [user1, user2]) }
  scope :for_client, ->(client) { where(client: client) }
  scope :internal_only, -> { where(message_type: 'internal') }
  scope :client_visible, -> { where(message_type: 'client_communication') }
  
  def created_at_formatted
    created_at.strftime("%B %d, %Y at %I:%M %p")
  end
  
  def is_internal?
    message_type == 'internal'
  end
  
  def is_client_communication?
    message_type == 'client_communication'
  end
end
