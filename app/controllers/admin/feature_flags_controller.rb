class Admin::FeatureFlagsController < ApplicationController
  before_action :require_admin
  before_action :set_feature_flag, only: [:show, :edit, :update, :destroy]
  
  def index
    @feature_flags = FeatureFlag.all.order(:name)
    
    render inertia: 'Admin/FeatureFlags/Index', props: {
      user: user_props,
      feature_flags: @feature_flags.map { |flag| feature_flag_props(flag) }
    }
  end
  
  def new
    render inertia: 'Admin/FeatureFlags/New', props: {
      user: user_props
    }
  end
  
  def create
    @feature_flag = FeatureFlag.new(feature_flag_params)
    
    if @feature_flag.save
      redirect_to admin_feature_flags_path, notice: 'Feature flag created successfully.'
    else
      render inertia: 'Admin/FeatureFlags/New', props: {
        user: user_props,
        errors: @feature_flag.errors.full_messages,
        feature_flag: feature_flag_props(@feature_flag)
      }
    end
  end
  
  def edit
    @users = User.all.order(:name)
    @user_access = @feature_flag.user_feature_accesses.includes(:user)
    
    render inertia: 'Admin/FeatureFlags/Edit', props: {
      user: user_props,
      feature_flag: feature_flag_props(@feature_flag),
      users: @users.map { |user| user_props(user) },
      user_access: @user_access.map { |access| user_access_props(access) }
    }
  end
  
  def update
    if @feature_flag.update(feature_flag_params)
      redirect_to admin_feature_flags_path, notice: 'Feature flag updated successfully.'
    else
      render inertia: 'Admin/FeatureFlags/Edit', props: {
        user: user_props,
        feature_flag: feature_flag_props(@feature_flag),
        errors: @feature_flag.errors.full_messages
      }
    end
  end
  
  def destroy
    title = @feature_flag.display_name
    if @feature_flag.destroy
      redirect_to admin_feature_flags_path, notice: "Feature flag '#{title}' deleted successfully!"
    else
      redirect_to admin_feature_flags_path, alert: "Failed to delete feature flag '#{title}'."
    end
  end
  
  def update_user_access
    user = User.find(params[:user_id])
    feature_flag = FeatureFlag.find(params[:feature_flag_id])
    
    success = FeatureFlagService.update_user_access(
      user, 
      feature_flag.name, 
      params[:enabled] == 'true',
      params[:settings] || {}
    )
    
    if success
      render json: { success: true }
    else
      render json: { success: false, error: 'Failed to update user access' }
    end
  end
  
  private
  
  def set_feature_flag
    @feature_flag = FeatureFlag.find(params[:id])
  end
  
  def feature_flag_params
    params.require(:feature_flag).permit(
      :name, :description, :enabled, 
      settings: [:employee_enabled, :client_enabled, :default_settings]
    )
  end
  
  def feature_flag_props(flag)
    {
      id: flag.id,
      name: flag.name,
      display_name: flag.display_name,
      description: flag.description,
      enabled: flag.enabled,
      settings: flag.settings,
      created_at: flag.created_at.strftime("%B %d, %Y"),
      updated_at: flag.updated_at.strftime("%B %d, %Y")
    }
  end
  
  def user_access_props(access)
    {
      id: access.id,
      user_id: access.user_id,
      feature_flag_id: access.feature_flag_id,
      enabled: access.enabled,
      settings: access.settings,
      user: user_props(access.user)
    }
  end
end
