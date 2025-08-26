class MessagesController < ApplicationController
  before_action :require_login
  before_action :set_message, only: [:show]

  def index
    Rails.logger.info "Messages accessed by user: #{@current_user.name} (Role: #{@current_user.role})"
    
    # Get accessible messages based on user role
    messages = @current_user.accessible_messages.recent.limit(20)
    
    render inertia: 'Messages/Index', props: {
      user: user_props,
      messages: messages.map { |message| message_props(message) },
      can_send_messages: @current_user.employee?
    }
  end

  def show
    unless can_access_message?(@message)
      redirect_to messages_path, alert: "Access denied."
      return
    end
    
    render inertia: 'Messages/Show', props: {
      user: user_props,
      message: message_props(@message)
    }
  end

  def create
    unless @current_user.employee?
      redirect_to messages_path, alert: "Access denied. Only employees can send messages."
      return
    end
    
    @message = Message.new(message_params)
    @message.sender = @current_user
    
    if @message.save
      render inertia: 'Messages/Index', props: {
        user: user_props,
        messages: @current_user.accessible_messages.recent.limit(20).map { |message| message_props(message) },
        success_message: "Message sent successfully!"
      }
    else
      render inertia: 'Messages/Index', props: {
        user: user_props,
        messages: @current_user.accessible_messages.recent.limit(20).map { |message| message_props(message) },
        errors: @message.errors.full_messages,
        message: { 
          subject: message_params[:subject], 
          content: message_params[:content],
          client_id: message_params[:client_id],
          recipient_id: message_params[:recipient_id],
          message_type: message_params[:message_type]
        }
      }
    end
  end

  private

  def set_message
    @message = @current_user.accessible_messages.find(params[:id])
  end

  def message_params
    params.require(:message).permit(:subject, :content, :client_id, :recipient_id, :message_type)
  end

  def can_access_message?(message)
    return true if @current_user.admin?
    return true if message.sender == @current_user || message.recipient == @current_user
    return true if @current_user.client? && message.client == @current_user.client_profile
    false
  end

  def message_props(message)
    {
      id: message.id,
      subject: message.subject,
      content: message.content,
      message_type: message.message_type,
      created_at: format_datetime(message.created_at),
      sender_name: message.sender.name,
      sender_id: message.sender.id,
      recipient_name: message.recipient.name,
      recipient_id: message.recipient.id,
      client_name: message.client.name,
      client_id: message.client.id,
      is_internal: message.is_internal?,
      is_client_communication: message.is_client_communication?
    }
  end
end
