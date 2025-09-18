class RegistrationsController < ApplicationController
  def new
    render inertia: 'Auth/Signup'
  end

  def create
    @user = User.new(user_params)
    
    if @user.save
      session[:user_id] = @user.id
      Rails.logger.info "Registration successful for user: #{@user.name}"
      redirect_to dashboard_path
    else
      Rails.logger.info "Registration failed: #{@user.errors.full_messages.join(', ')}"
      render inertia: 'Auth/Signup', props: { 
        errors: @user.errors.full_messages,
        user: @user.attributes.except('password_digest')
      }
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role)
  end
end
