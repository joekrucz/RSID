class PeopleController < ApplicationController
  before_action :require_login, except: [:new, :create]
  before_action :set_person, only: [:show, :update, :destroy, :update_role]

  def index
    Rails.logger.info "People accessed by user: #{@current_user.name} (Role: #{@current_user.role})"
    
    # Get search and filter parameters
    search = params[:search]&.strip
    role_filter = params[:role_filter]&.strip
    sort_by = params[:sort_by] || 'name'
    sort_order = params[:sort_order] || 'asc'
    
    # Get accessible people based on user role
    people = User.filtered_and_sorted(@current_user, search: search, role_filter: role_filter, sort_by: sort_by, sort_order: sort_order)
    
    render inertia: 'People/Index', props: {
      user: user_props,
      people: people.map { |person| person_props(person) },
      search: search,
      role_filter: role_filter,
      sort_by: sort_by,
      sort_order: sort_order,
      can_manage_roles: @current_user.admin?,
      can_create_people: @current_user.employee?,
      stats: calculate_stats(people)
    }
  end

  def show
    unless can_view_person?(@person)
      redirect_to people_path, alert: "Access denied."
      return
    end
    
    render inertia: 'People/Show', props: {
      user: user_props,
      person: person_props(@person),
      can_edit: can_edit_person?(@person),
      can_change_role: @current_user.admin? && @person.id != @current_user.id
    }
  end

  def new
    # Allow signup for new users (no current user) or employees creating new people
    if @current_user && !@current_user.employee?
      redirect_to people_path, alert: "Access denied. Only employees can create new people."
      return
    end
    
    render inertia: 'People/New', props: {
      user: user_props
    }
  end

  def create
    # Allow signup for new users (no current user) or employees creating new people
    if @current_user && !@current_user.employee?
      redirect_to people_path, alert: "Access denied. Only employees can create new people."
      return
    end
    
    @person = User.new(person_params)
    @person.role = :client # Default to client role
    
    if @person.save
      if @current_user
        # Employee creating a new person
        redirect_to people_path, notice: "Person '#{@person.name}' created successfully!"
      else
        # New user signup
        session[:user_id] = @person.id
        redirect_to "/dashboard", notice: "Client account created successfully! Welcome to RSID App, #{@person.name}!", status: :see_other
      end
    else
      render inertia: 'People/New', props: {
        user: user_props,
        errors: @person.errors.full_messages,
        person: { 
          name: person_params[:name], 
          email: person_params[:email]
        }
      }
    end
  end

  def update
    unless can_edit_person?(@person)
      redirect_to people_path, alert: "Access denied."
      return
    end
    
    if @person.update(person_params)
      redirect_to people_path, notice: "Person '#{@person.name}' updated successfully!"
    else
      render inertia: 'People/Show', props: {
        user: user_props,
        person: person_props(@person),
        errors: @person.errors.full_messages,
        can_edit: can_edit_person?(@person),
        can_change_role: @current_user.admin? && @person.id != @current_user.id
      }
    end
  end

  def update_role
    unless @current_user.admin? && @person.id != @current_user.id
      redirect_to people_path, alert: "Access denied."
      return
    end
    
    if @person.update(role: params[:role])
      redirect_to people_path, notice: "Role updated successfully for #{@person.name}!"
    else
      redirect_to people_path, alert: "Failed to update role for #{@person.name}."
    end
  end

  def destroy
    unless @current_user.admin? && @person.id != @current_user.id
      redirect_to people_path, alert: "Access denied."
      return
    end
    
    name = @person.name
    if @person.destroy
      redirect_to people_path, notice: "Person '#{name}' deleted successfully!"
    else
      redirect_to people_path, alert: "Failed to delete person '#{name}'."
    end
  end

  private

  def set_person
    @person = User.find(params[:id])
  end

  def person_params
    params.require(:person).permit(:name, :email, :password, :password_confirmation)
  end



  def can_view_person?(person)
    @current_user.admin? || 
    @current_user.employee? || 
    person.id == @current_user.id
  end

  def can_edit_person?(person)
    @current_user.admin? || 
    (@current_user.employee? && person.role == 'client') ||
    person.id == @current_user.id
  end

  def person_props(person)
    {
      id: person.id,
      name: person.name,
      email: person.email,
      role: person.role,
      isEmployee: person.employee?,
      isAdmin: person.admin?,
      isClient: person.client?,
      created_at: person.created_at.strftime("%B %d, %Y"),
      updated_at: person.updated_at.strftime("%B %d, %Y")
    }
  end

  def calculate_stats(people)
    {
      total: people.count,
      clients: people.where(role: 'client').count,
      employees: people.where(role: 'employee').count,
      admins: people.where(role: 'admin').count
    }
  end
end 