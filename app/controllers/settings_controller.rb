class SettingsController < ApplicationController
  before_action :require_login

  def index
    Rails.logger.info "Settings accessed by user: #{@current_user.name}"
    render inertia: 'Settings/Index', props: {
      user: user_props
    }
  end
end 