class PagesController < ApplicationController
  def home
    Rails.logger.info "Home action called - Current user: #{@current_user&.name}, Logged in: #{logged_in?}"
    render inertia: 'Pages/Home', props: {
      user: user_props,
      logged_in: logged_in?
    }
  end
end
