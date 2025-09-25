class SessionsController < ApplicationController
  def new
    render inertia: 'Auth/Login'
  end

  def create
    user = User.find_by(email: params[:email])
    
    if user&.authenticate(params[:password])
      # Preserve forwarding URL across reset_session
      intended_url = session[:forwarding_url]
      reset_session
      session[:user_id] = user.id
      Rails.logger.info "Login successful for user: #{user.name}, session[:user_id] = #{session[:user_id]}"
      Rails.logger.info "Session after login: #{session.to_hash}"
      Rails.logger.info "Session ID: #{session.id}"
      
      # Friendly forwarding: redirect to intended URL if present
      redirect_to(intended_url.present? ? intended_url : dashboard_path)
    else
      Rails.logger.info "Login failed for email: #{params[:email]}"
      # Return the same page with error props
      render inertia: 'Auth/Login', props: { 
        errors: { email: "Invalid email or password" },
        email: params[:email]
      }
    end
  end

  def destroy
    session[:user_id] = nil
    # Use Inertia redirect to the landing page
    redirect_to root_path
  end
end
