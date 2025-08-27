class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true
  
  enum :notification_type, {
    project_created: 0,
    project_updated: 1,
    message_received: 2,
    todo_due: 3,
    grant_submitted: 4,
    system_alert: 5
  }
  
  validates :title, presence: true
  validates :message, presence: true
  validates :notification_type, presence: true
  
  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(notification_type: type) }
  
  def mark_as_read!
    update!(read: true, read_at: Time.current)
  end
  
  def self.create_for_user(user, type, title, message, notifiable = nil)
    notification = create!(
      user: user,
      notification_type: type,
      title: title,
      message: message,
      notifiable: notifiable
    )
    
    # Broadcast to ActionCable
    NotificationsChannel.broadcast_to(user, {
      id: notification.id,
      type: notification.notification_type,
      title: notification.title,
      message: notification.message,
      created_at: notification.created_at.strftime("%B %d, %Y at %I:%M %p"),
      read: notification.read
    })
    
    notification
  end
end
