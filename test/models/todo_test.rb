require "test_helper"

class TodoTest < ActiveSupport::TestCase
  def setup
    @user = users(:admin_user)
    @todo = todos(:one)
  end

  # Validations
  test "should be valid with valid attributes" do
    todo = Todo.new(
      title: "Test Todo",
      description: "Test description",
      user: @user,
      priority: "medium",
      completed: false
    )
    assert todo.valid?
  end

  test "should require title" do
    todo = Todo.new(description: "Test description", user: @user)
    assert_not todo.valid?
    assert_includes todo.errors[:title], "can't be blank"
  end

  test "should require title minimum length" do
    todo = Todo.new(title: "", description: "Test description", user: @user)
    assert_not todo.valid?
    assert_includes todo.errors[:title], "can't be blank"
  end

  test "should require title maximum length" do
    todo = Todo.new(
      title: "a" * 256,
      description: "Test description",
      user: @user
    )
    assert_not todo.valid?
    assert_includes todo.errors[:title], "is too long (maximum is 255 characters)"
  end

  test "should require user" do
    todo = Todo.new(title: "Test Todo", description: "Test description")
    assert_not todo.valid?
    assert_includes todo.errors[:user], "must exist"
  end

  test "should validate priority inclusion" do
    todo = Todo.new(
      title: "Test Todo",
      description: "Test description",
      user: @user,
      priority: "invalid"
    )
    assert_not todo.valid?
    assert_includes todo.errors[:priority], "is not included in the list"
  end

  test "should accept valid priorities" do
    valid_priorities = %w[low medium high]
    valid_priorities.each do |priority|
      todo = Todo.new(
        title: "Test Todo",
        description: "Test description",
        user: @user,
        priority: priority
      )
      assert todo.valid?, "#{priority} should be valid"
    end
  end

  test "should allow nil priority" do
    todo = Todo.new(
      title: "Test Todo",
      description: "Test description",
      user: @user,
      priority: nil
    )
    assert todo.valid?
  end

  # Associations
  test "should belong to user" do
    assert_respond_to @todo, :user
  end

  # Scopes
  test "should filter by user" do
    user_todos = Todo.by_user(@user)
    assert user_todos.all? { |todo| todo.user == @user }
  end

  test "should find active todos" do
    active_todos = Todo.active
    assert active_todos.all? { |todo| !todo.completed }
  end

  test "should find completed todos" do
    completed_todos = Todo.completed
    assert completed_todos.all? { |todo| todo.completed }
  end

  test "should find recent todos" do
    recent_todos = Todo.recent
    assert_equal recent_todos.order(:created_at).reverse, recent_todos
  end

  test "should filter by priority" do
    medium_todos = Todo.by_priority("medium")
    assert medium_todos.all? { |todo| todo.priority == "medium" }
  end

  test "should find due soon todos" do
    due_soon_todos = Todo.due_soon
    assert due_soon_todos.all? { |todo| 
      todo.due_date && 
      todo.due_date <= 7.days.from_now && 
      !todo.completed 
    }
  end

  test "should find overdue todos" do
    overdue_todos = Todo.overdue
    assert overdue_todos.all? { |todo| 
      todo.due_date && 
      todo.due_date < Date.current && 
      !todo.completed 
    }
  end

  test "should find completed today todos" do
    completed_today_todos = Todo.completed_today
    assert completed_today_todos.all? { |todo| 
      todo.completed && 
      todo.updated_at.to_date == Date.current 
    }
  end

  test "should search by content" do
    search_results = Todo.search_by_content("test")
    assert search_results.all? { |todo| 
      todo.title.downcase.include?("test") || 
      todo.description.downcase.include?("test") 
    }
  end

  test "should filter by status" do
    active_todos = Todo.filter_by_status("active")
    assert active_todos.all? { |todo| !todo.completed }
    
    completed_todos = Todo.filter_by_status("completed")
    assert completed_todos.all? { |todo| todo.completed }
    
    all_todos = Todo.filter_by_status("invalid")
    assert_equal Todo.count, all_todos.count
  end

  test "should sort by field" do
    sorted_todos = Todo.sorted_by("title", "ASC")
    assert_equal sorted_todos.first.title, sorted_todos.min_by(&:title).title
  end

  # Instance methods
  test "should detect overdue todos" do
    overdue_todo = Todo.new(
      title: "Overdue Todo",
      description: "Test description",
      user: @user,
      due_date: 1.day.ago,
      completed: false
    )
    assert overdue_todo.overdue?
  end

  test "should not detect completed todos as overdue" do
    completed_overdue_todo = Todo.new(
      title: "Completed Overdue Todo",
      description: "Test description",
      user: @user,
      due_date: 1.day.ago,
      completed: true
    )
    assert_not completed_overdue_todo.overdue?
  end

  test "should detect due soon todos" do
    due_soon_todo = Todo.new(
      title: "Due Soon Todo",
      description: "Test description",
      user: @user,
      due_date: 3.days.from_now,
      completed: false
    )
    assert due_soon_todo.due_soon?
  end

  test "should not detect overdue todos as due soon" do
    overdue_todo = Todo.new(
      title: "Overdue Todo",
      description: "Test description",
      user: @user,
      due_date: 1.day.ago,
      completed: false
    )
    assert_not overdue_todo.due_soon?
  end

  test "should not detect completed todos as due soon" do
    completed_todo = Todo.new(
      title: "Completed Todo",
      description: "Test description",
      user: @user,
      due_date: 3.days.from_now,
      completed: true
    )
    assert_not completed_todo.due_soon?
  end

  # Class methods
  test "filtered_and_sorted should handle search" do
    results = Todo.filtered_and_sorted(@user, search: "test")
    assert results.all? { |todo| 
      todo.title.downcase.include?("test") || 
      todo.description.downcase.include?("test") 
    }
  end

  test "filtered_and_sorted should handle status filter" do
    active_results = Todo.filtered_and_sorted(@user, filter: "active")
    assert active_results.all? { |todo| !todo.completed }
    
    completed_results = Todo.filtered_and_sorted(@user, filter: "completed")
    assert completed_results.all? { |todo| todo.completed }
  end

  test "filtered_and_sorted should handle sorting" do
    asc_results = Todo.filtered_and_sorted(@user, sort_by: "title", sort_order: "ASC")
    desc_results = Todo.filtered_and_sorted(@user, sort_by: "title", sort_order: "DESC")
    
    assert_not_equal asc_results.first.title, desc_results.first.title
  end

  test "filtered_and_sorted should filter by user" do
    results = Todo.filtered_and_sorted(@user)
    assert results.all? { |todo| todo.user == @user }
  end

  # Callbacks
  test "should set completed to false if blank" do
    todo = Todo.new(
      title: "Test Todo",
      description: "Test description",
      user: @user,
      completed: nil
    )
    todo.save
    assert_not todo.completed
  end
end
