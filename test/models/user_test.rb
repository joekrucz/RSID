require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:admin_user)
    @client = users(:client_user)
    @employee = users(:employee_user)
  end

  # Validations
  test "should be valid with valid attributes" do
    user = User.new(
      name: "Test User",
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :client
    )
    assert user.valid?
  end

  test "should require name" do
    user = User.new(email: "test@example.com", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "should require email" do
    user = User.new(name: "Test User", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "should require unique email" do
    user = User.new(
      name: "Test User",
      email: @user.email,
      password: "password123"
    )
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "should require valid email format" do
    user = User.new(
      name: "Test User",
      email: "invalid-email",
      password: "password123"
    )
    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  test "should require minimum password length" do
    user = User.new(
      name: "Test User",
      email: "test@example.com",
      password: "12345"
    )
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 6 characters)"
  end

  # Associations
  test "should have many notes" do
    assert_respond_to @user, :notes
  end

  test "should have many todos" do
    assert_respond_to @user, :todos
  end

  test "should have many file_items" do
    assert_respond_to @user, :file_items
  end

  test "should have many grant_applications" do
    assert_respond_to @user, :grant_applications
  end

  test "should have many rnd_projects" do
    assert_respond_to @user, :rnd_projects
  end

  test "should have many feature_flags through user_feature_accesses" do
    assert_respond_to @user, :feature_flags
  end

  # Role methods
  test "should identify admin correctly" do
    assert @user.admin?
    assert_not @client.admin?
    assert_not @employee.admin?
  end

  test "should identify employee correctly" do
    assert @employee.employee?
    assert @user.employee? # admin is also employee
    assert_not @client.employee?
  end

  test "should identify client correctly" do
    assert @client.client?
    assert_not @user.client?
    assert_not @employee.client?
  end

  # Permission methods
  test "should allow employees to manage clients" do
    assert @user.can_manage_clients?
    assert @employee.can_manage_clients?
    assert_not @client.can_manage_clients?
  end

  test "should allow employees to access grant pipeline" do
    assert @user.can_access_grant_pipeline?
    assert @employee.can_access_grant_pipeline?
    assert_not @client.can_access_grant_pipeline?
  end

  test "should allow employees to view internal notes" do
    assert @user.can_view_internal_notes?
    assert @employee.can_view_internal_notes?
    assert_not @client.can_view_internal_notes?
  end

  # Scopes
  test "should filter by role" do
    assert_includes User.by_role(:admin), @user
    assert_includes User.by_role(:client), @client
    assert_includes User.by_role(:employee), @employee
  end

  test "should find clients" do
    clients = User.clients
    assert_includes clients, @client
    assert_not_includes clients, @user
    assert_not_includes clients, @employee
  end

  test "should find employees" do
    employees = User.employees
    assert_includes employees, @employee
    assert_not_includes employees, @client
  end

  test "should find admins" do
    admins = User.admins
    assert_includes admins, @user
    assert_not_includes admins, @client
    assert_not_includes admins, @employee
  end

  test "should search by name or email" do
    results = User.search_by_name_or_email("admin")
    assert_includes results, @user
    
    results = User.search_by_name_or_email(@user.email)
    assert_includes results, @user
  end

  test "should sort by field" do
    users = User.sorted_by("name", "ASC")
    assert_equal users.first.name, users.min_by(&:name).name
  end

  # Class methods
  test "filtered_and_sorted should handle admin access" do
    results = User.filtered_and_sorted(@user)
    assert_equal User.count, results.count
  end

  test "filtered_and_sorted should handle employee access" do
    results = User.filtered_and_sorted(@employee)
    assert_equal User.count, results.count
  end

  test "filtered_and_sorted should handle client access" do
    results = User.filtered_and_sorted(@client)
    assert_equal 1, results.count
    assert_includes results, @client
  end

  test "filtered_and_sorted should apply search filter" do
    results = User.filtered_and_sorted(@user, search: @user.name)
    assert_includes results, @user
  end

  test "filtered_and_sorted should apply role filter" do
    results = User.filtered_and_sorted(@user, role_filter: "client")
    assert_includes results, @client
    assert_not_includes results, @user
  end

  # Feature flag methods
  test "should check feature enabled" do
    # This would need a feature flag fixture to test properly
    assert_respond_to @user, :feature_enabled?
  end

  test "should get available features" do
    assert_respond_to @user, :available_features
    assert_kind_of Array, @user.available_features
  end

  # Access control methods
  test "should get accessible clients for admin" do
    clients = @user.accessible_clients
    assert_kind_of ActiveRecord::Relation, clients
  end

  test "should get accessible clients for employee" do
    clients = @employee.accessible_clients
    assert_kind_of ActiveRecord::Relation, clients
  end

  test "should get accessible clients for client" do
    clients = @client.accessible_clients
    assert_kind_of Array, clients
  end

  test "should get accessible messages" do
    messages = @user.accessible_messages
    assert_kind_of ActiveRecord::Relation, messages
  end
end
