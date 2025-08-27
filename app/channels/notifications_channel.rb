class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    return reject unless current_user
    
    stream_for current_user
    log_user_action("notifications_subscribed")
  end

  def unsubscribed
    log_user_action("notifications_unsubscribed") if current_user
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def log_user_action(action)
    Rails.logger.info "NotificationsChannel: #{current_user&.name} - #{action}"
  end
end
