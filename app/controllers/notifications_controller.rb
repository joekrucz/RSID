class NotificationsController < ApplicationController
  before_action :require_login
  before_action :set_notification, only: [:mark_as_read, :destroy]

  def index
    log_user_action("viewed_notifications")
    
    notifications = @current_user.notifications.recent.limit(50)
    
    render inertia: 'Notifications/Index', props: {
      user: user_props,
      notifications: notifications.map { |notification| notification_props(notification) },
      unread_count: @current_user.notifications.unread.count
    }
  end

  def mark_as_read
    @notification.mark_as_read!
    log_user_action("marked_notification_read", { notification_id: @notification.id })
    
    render json: { success: true }
  end

  def mark_all_as_read
    @current_user.notifications.unread.update_all(read: true, read_at: Time.current)
    log_user_action("marked_all_notifications_read")
    
    render json: { success: true }
  end

  def destroy
    @notification.destroy
    log_user_action("deleted_notification", { notification_id: @notification.id })
    
    render json: { success: true }
  end

  private

  def set_notification
    @notification = @current_user.notifications.find(params[:id])
  end

  def notification_props(notification)
    {
      id: notification.id,
      title: notification.title,
      message: notification.message,
      type: notification.notification_type,
      read: notification.read,
      created_at: notification.created_at.strftime("%B %d, %Y at %I:%M %p"),
      notifiable_type: notification.notifiable_type,
      notifiable_id: notification.notifiable_id
    }
  end
end
