require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:admin_user)
  end

  test "should get new login page" do
    get login_path
    assert_response :success
    assert_select "h1", "Login"
  end

  test "should redirect to dashboard after successful login" do
    post login_path, params: {
      email: @user.email,
      password: "password123"
    }
    assert_redirected_to dashboard_path
    assert_equal @user.id, session[:user_id]
  end

  test "should not login with invalid email" do
    post login_path, params: {
      email: "invalid@example.com",
      password: "password123"
    }
    assert_response :unprocessable_entity
    assert_nil session[:user_id]
  end

  test "should not login with invalid password" do
    post login_path, params: {
      email: @user.email,
      password: "wrongpassword"
    }
    assert_response :unprocessable_entity
    assert_nil session[:user_id]
  end

  test "should not login with empty credentials" do
    post login_path, params: {
      email: "",
      password: ""
    }
    assert_response :unprocessable_entity
    assert_nil session[:user_id]
  end

  test "should logout successfully" do
    # First login
    post login_path, params: {
      email: @user.email,
      password: "password123"
    }
    assert_equal @user.id, session[:user_id]

    # Then logout
    delete logout_path
    assert_redirected_to root_path
    assert_nil session[:user_id]
  end

  test "should redirect to dashboard if already logged in" do
    # Login first
    post login_path, params: {
      email: @user.email,
      password: "password123"
    }
    
    # Try to access login page again
    get login_path
    assert_redirected_to dashboard_path
  end

  test "should handle login with different user roles" do
    # Test admin login
    admin = users(:admin_user)
    post login_path, params: {
      email: admin.email,
      password: "password123"
    }
    assert_redirected_to dashboard_path
    assert_equal admin.id, session[:user_id]

    # Logout
    delete logout_path

    # Test employee login
    employee = users(:employee_user)
    post login_path, params: {
      email: employee.email,
      password: "password123"
    }
    assert_redirected_to dashboard_path
    assert_equal employee.id, session[:user_id]

    # Logout
    delete logout_path

    # Test client login
    client = users(:client_user)
    post login_path, params: {
      email: client.email,
      password: "password123"
    }
    assert_redirected_to dashboard_path
    assert_equal client.id, session[:user_id]
  end

  test "should handle case insensitive email login" do
    post login_path, params: {
      email: @user.email.upcase,
      password: "password123"
    }
    assert_redirected_to dashboard_path
    assert_equal @user.id, session[:user_id]
  end

  test "should handle login with extra whitespace" do
    post login_path, params: {
      email: " #{@user.email} ",
      password: "password123"
    }
    assert_redirected_to dashboard_path
    assert_equal @user.id, session[:user_id]
  end
end
