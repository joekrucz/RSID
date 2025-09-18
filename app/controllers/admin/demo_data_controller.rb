# Admin::DemoDataController
# 
# Handles demo data creation and management for development purposes.
# Extracted from GrantApplicationsController to separate concerns.
class Admin::DemoDataController < ApplicationController
  before_action :require_admin
  before_action :require_development_environment

  def link_companies
    result = DemoDataService.new.link_companies
    render json: result
  end

  def add_demo_data
    result = DemoDataService.new.add_demo_data
    render json: result
  end

  def add_massive_demo_data
    result = DemoDataService.new.add_massive_demo_data
    render json: result
  end

  def debug_data
    result = DemoDataService.new.debug_data(@current_user)
    render json: result
  end

  def fix_company_links
    result = DemoDataService.new.fix_company_links(@current_user)
    render json: result
  end

  private

  def require_development_environment
    redirect_to root_path unless Rails.env.development?
  end
end
