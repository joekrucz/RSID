class DashboardController < ApplicationController
  before_action :require_login

  def index
    render inertia: 'Dashboard/Index', props: dashboard_props
  end

  private

  def dashboard_props
    DashboardService.new(@current_user).call
  end
end