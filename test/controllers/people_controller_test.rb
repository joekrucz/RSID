require "test_helper"

class PeopleControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    @employee = users(:employee_user)
    @client = users(:client_user)
  end

  # Index action tests
  test "should get index when logged in as admin" do
    login_as(@admin)
    get people_path
    assert_response :success
  end

  test "should get index when logged in as employee" do
    login_as(@employee)
    get people_path
    assert_response :success
  end

  test "should redirect to login when not authenticated" do
    get people_path
    assert_redirected_to login_path
  end

  test "should deny access to clients" do
    login_as(@client)
    get people_path
    assert_redirected_to root_path
  end

  test "should filter people by search term" do
    login_as(@admin)
    get people_path, params: { search: "admin" }
    assert_response :success
  end

  test "should filter people by role" do
    login_as(@admin)
    get people_path, params: { role_filter: "client" }
    assert_response :success
  end

  test "should sort people by field" do
    login_as(@admin)
    get people_path, params: { sort_by: "name", sort_order: "asc" }
    assert_response :success
  end

  # Show action tests
  test "should show person when admin" do
    login_as(@admin)
    get person_path(@client)
    assert_response :success
  end

  test "should show person when employee" do
    login_as(@employee)
    get person_path(@client)
    assert_response :success
  end

  test "should show own profile when client" do
    login_as(@client)
    get person_path(@client)
    assert_response :success
  end

  test "should deny access to other profiles when client" do
    login_as(@client)
    get person_path(@admin)
    assert_redirected_to people_path
  end

  # New action tests
  test "should get new when employee" do
    login_as(@employee)
    get new_person_path
    assert_response :success
  end

  test "should get new when admin" do
    login_as(@admin)
    get new_person_path
    assert_response :success
  end

  test "should deny new access to clients" do
    login_as(@client)
    get new_person_path
    assert_redirected_to people_path
  end

  test "should allow signup for new users" do
    get new_person_path
    assert_response :success
  end

  # Create action tests
  test "should create person when employee" do
    login_as(@employee)
    assert_difference('User.count') do
      post people_path, params: {
        person: {
          name: "New Person",
          email: "newperson@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    assert_redirected_to people_path
  end

  test "should create person when admin" do
    login_as(@admin)
    assert_difference('User.count') do
      post people_path, params: {
        person: {
          name: "New Person",
          email: "newperson@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    assert_redirected_to people_path
  end

  test "should deny create access to clients" do
    login_as(@client)
    assert_no_difference('User.count') do
      post people_path, params: {
        person: {
          name: "New Person",
          email: "newperson@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    assert_redirected_to people_path
  end

  test "should allow signup for new users" do
    assert_difference('User.count') do
      post people_path, params: {
        person: {
          name: "New Client",
          email: "newclient@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    assert_redirected_to dashboard_path
  end

  test "should not create person with invalid data" do
    login_as(@employee)
    assert_no_difference('User.count') do
      post people_path, params: {
        person: {
          name: "",
          email: "invalid-email",
          password: "short",
          password_confirmation: "short"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # Edit action tests
  test "should get edit when admin" do
    login_as(@admin)
    get edit_person_path(@client)
    assert_response :success
  end

  test "should get edit when employee editing client" do
    login_as(@employee)
    get edit_person_path(@client)
    assert_response :success
  end

  test "should get edit own profile when client" do
    login_as(@client)
    get edit_person_path(@client)
    assert_response :success
  end

  test "should deny edit access to other profiles when client" do
    login_as(@client)
    get edit_person_path(@admin)
    assert_redirected_to people_path
  end

  # Update action tests
  test "should update person when admin" do
    login_as(@admin)
    patch person_path(@client), params: {
      person: { name: "Updated Name" }
    }
    assert_redirected_to people_path
    @client.reload
    assert_equal "Updated Name", @client.name
  end

  test "should update person when employee editing client" do
    login_as(@employee)
    patch person_path(@client), params: {
      person: { name: "Updated Name" }
    }
    assert_redirected_to people_path
    @client.reload
    assert_equal "Updated Name", @client.name
  end

  test "should update own profile when client" do
    login_as(@client)
    patch person_path(@client), params: {
      person: { name: "Updated Name" }
    }
    assert_redirected_to people_path
    @client.reload
    assert_equal "Updated Name", @client.name
  end

  test "should deny update access to other profiles when client" do
    login_as(@client)
    patch person_path(@admin), params: {
      person: { name: "Updated Name" }
    }
    assert_redirected_to people_path
    @admin.reload
    assert_not_equal "Updated Name", @admin.name
  end

  test "should not update with invalid data" do
    login_as(@admin)
    patch person_path(@client), params: {
      person: { email: "invalid-email" }
    }
    assert_response :unprocessable_entity
  end

  # Update role action tests
  test "should update role when admin" do
    login_as(@admin)
    patch update_role_person_path(@client), params: { role: "employee" }
    assert_redirected_to people_path
    @client.reload
    assert_equal "employee", @client.role
  end

  test "should deny role update when not admin" do
    login_as(@employee)
    patch update_role_person_path(@client), params: { role: "employee" }
    assert_redirected_to people_path
    @client.reload
    assert_equal "client", @client.role
  end

  test "should deny role update of own account" do
    login_as(@admin)
    patch update_role_person_path(@admin), params: { role: "client" }
    assert_redirected_to people_path
    @admin.reload
    assert_equal "admin", @admin.role
  end

  # Destroy action tests
  test "should destroy person when admin" do
    login_as(@admin)
    assert_difference('User.count', -1) do
      delete person_path(@client)
    end
    assert_redirected_to people_path
  end

  test "should deny destroy when not admin" do
    login_as(@employee)
    assert_no_difference('User.count') do
      delete person_path(@client)
    end
    assert_redirected_to people_path
  end

  test "should deny destroy of own account" do
    login_as(@admin)
    assert_no_difference('User.count') do
      delete person_path(@admin)
    end
    assert_redirected_to people_path
  end

  private

  def login_as(user)
    post login_path, params: {
      email: user.email,
      password: "password123"
    }
  end
end 