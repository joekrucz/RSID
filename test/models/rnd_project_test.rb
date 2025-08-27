require "test_helper"

class RndProjectTest < ActiveSupport::TestCase
  def setup
    @user = users(:admin_user)
    @client = users(:client_user)
    @project = rnd_projects(:one)
  end

  # Validations
  test "should be valid with valid attributes" do
    project = RndProject.new(
      title: "Test R&D Project",
      description: "This is a test R&D project description",
      start_date: Date.current,
      end_date: 1.month.from_now.to_date,
      qualifying_activities: "Research and development activities",
      technical_challenges: "Technical challenges description",
      client: @client,
      status: :draft
    )
    assert project.valid?
  end

  test "should require title" do
    project = RndProject.new(
      description: "Test description",
      start_date: Date.current,
      end_date: 1.month.from_now.to_date,
      qualifying_activities: "Research activities",
      technical_challenges: "Technical challenges",
      client: @client
    )
    assert_not project.valid?
    assert_includes project.errors[:title], "can't be blank"
  end

  test "should require title minimum length" do
    project = RndProject.new(
      title: "ab",
      description: "Test description",
      start_date: Date.current,
      end_date: 1.month.from_now.to_date,
      qualifying_activities: "Research activities",
      technical_challenges: "Technical challenges",
      client: @client
    )
    assert_not project.valid?
    assert_includes project.errors[:title], "is too short (minimum is 3 characters)"
  end

  test "should require description" do
    project = RndProject.new(
      title: "Test Project",
      start_date: Date.current,
      end_date: 1.month.from_now.to_date,
      qualifying_activities: "Research activities",
      technical_challenges: "Technical challenges",
      client: @client
    )
    assert_not project.valid?
    assert_includes project.errors[:description], "can't be blank"
  end

  test "should require description minimum length" do
    project = RndProject.new(
      title: "Test Project",
      description: "short",
      start_date: Date.current,
      end_date: 1.month.from_now.to_date,
      qualifying_activities: "Research activities",
      technical_challenges: "Technical challenges",
      client: @client
    )
    assert_not project.valid?
    assert_includes project.errors[:description], "is too short (minimum is 10 characters)"
  end

  test "should require start_date" do
    project = RndProject.new(
      title: "Test Project",
      description: "Test description",
      end_date: 1.month.from_now.to_date,
      qualifying_activities: "Research activities",
      technical_challenges: "Technical challenges",
      client: @client
    )
    assert_not project.valid?
    assert_includes project.errors[:start_date], "can't be blank"
  end

  test "should require end_date" do
    project = RndProject.new(
      title: "Test Project",
      description: "Test description",
      start_date: Date.current,
      qualifying_activities: "Research activities",
      technical_challenges: "Technical challenges",
      client: @client
    )
    assert_not project.valid?
    assert_includes project.errors[:end_date], "can't be blank"
  end

  test "should require qualifying_activities" do
    project = RndProject.new(
      title: "Test Project",
      description: "Test description",
      start_date: Date.current,
      end_date: 1.month.from_now.to_date,
      technical_challenges: "Technical challenges",
      client: @client
    )
    assert_not project.valid?
    assert_includes project.errors[:qualifying_activities], "can't be blank"
  end

  test "should require qualifying_activities minimum length" do
    project = RndProject.new(
      title: "Test Project",
      description: "Test description",
      start_date: Date.current,
      end_date: 1.month.from_now.to_date,
      qualifying_activities: "short",
      technical_challenges: "Technical challenges",
      client: @client
    )
    assert_not project.valid?
    assert_includes project.errors[:qualifying_activities], "is too short (minimum is 10 characters)"
  end

  test "should require technical_challenges" do
    project = RndProject.new(
      title: "Test Project",
      description: "Test description",
      start_date: Date.current,
      end_date: 1.month.from_now.to_date,
      qualifying_activities: "Research activities",
      client: @client
    )
    assert_not project.valid?
    assert_includes project.errors[:technical_challenges], "can't be blank"
  end

  test "should require technical_challenges minimum length" do
    project = RndProject.new(
      title: "Test Project",
      description: "Test description",
      start_date: Date.current,
      end_date: 1.month.from_now.to_date,
      qualifying_activities: "Research activities",
      technical_challenges: "short",
      client: @client
    )
    assert_not project.valid?
    assert_includes project.errors[:technical_challenges], "is too short (minimum is 10 characters)"
  end

  test "should validate end_date after start_date" do
    project = RndProject.new(
      title: "Test Project",
      description: "Test description",
      start_date: 1.month.from_now.to_date,
      end_date: Date.current,
      qualifying_activities: "Research activities",
      technical_challenges: "Technical challenges",
      client: @client
    )
    assert_not project.valid?
    assert_includes project.errors[:end_date], "must be after start date"
  end

  # Associations
  test "should belong to client" do
    assert_respond_to @project, :client
  end

  test "should have many rnd_expenditures" do
    assert_respond_to @project, :rnd_expenditures
  end

  # Scopes
  test "should find recent projects" do
    recent_projects = RndProject.recent
    assert_equal recent_projects.order(:created_at).reverse, recent_projects
  end

  test "should filter by status" do
    draft_projects = RndProject.by_status(:draft)
    assert draft_projects.all? { |project| project.status == "draft" }
  end

  test "should filter by client" do
    client_projects = RndProject.by_client(@client.id)
    assert client_projects.all? { |project| project.client_id == @client.id }
  end

  test "should find active projects" do
    active_projects = RndProject.active_projects
    assert active_projects.all? { |project| 
      %w[active completed ready_for_claim].include?(project.status) 
    }
  end

  test "should search by content" do
    search_results = RndProject.search_by_content("test")
    assert search_results.all? { |project| 
      project.title.downcase.include?("test") || 
      project.description.downcase.include?("test") 
    }
  end

  test "should sort by field" do
    sorted_projects = RndProject.sorted_by("title", "ASC")
    assert_equal sorted_projects.first.title, sorted_projects.min_by(&:title).title
  end

  test "should sort by client name" do
    sorted_projects = RndProject.sorted_by("client", "ASC")
    assert_kind_of ActiveRecord::Relation, sorted_projects
  end

  test "should sort by total expenditure" do
    sorted_projects = RndProject.sorted_by("total_expenditure", "ASC")
    assert_kind_of ActiveRecord::Relation, sorted_projects
  end

  # Instance methods
  test "should calculate total expenditure" do
    assert_respond_to @project, :total_expenditure
    assert_kind_of Numeric, @project.total_expenditure
  end

  test "should calculate expenditure by type" do
    assert_respond_to @project, :expenditure_by_type
    assert_kind_of Hash, @project.expenditure_by_type
  end

  test "should calculate duration days" do
    project = RndProject.new(
      title: "Test Project",
      description: "Test description",
      start_date: Date.current,
      end_date: 30.days.from_now.to_date,
      qualifying_activities: "Research activities",
      technical_challenges: "Technical challenges",
      client: @client
    )
    assert_equal 30, project.duration_days
  end

  test "should return 0 duration days for missing dates" do
    project = RndProject.new(
      title: "Test Project",
      description: "Test description",
      qualifying_activities: "Research activities",
      technical_challenges: "Technical challenges",
      client: @client
    )
    assert_equal 0, project.duration_days
  end

  test "should detect active projects" do
    active_project = RndProject.new(status: :active)
    assert active_project.is_active?
    
    completed_project = RndProject.new(status: :completed)
    assert completed_project.is_active?
    
    ready_project = RndProject.new(status: :ready_for_claim)
    assert ready_project.is_active?
    
    draft_project = RndProject.new(status: :draft)
    assert_not draft_project.is_active?
  end

  test "should detect claimable projects" do
    project = RndProject.new(status: :ready_for_claim)
    allow(project).to receive(:total_expenditure).and_return(1000)
    assert project.can_be_claimed?
    
    project = RndProject.new(status: :ready_for_claim)
    allow(project).to receive(:total_expenditure).and_return(0)
    assert_not project.can_be_claimed?
    
    project = RndProject.new(status: :draft)
    allow(project).to receive(:total_expenditure).and_return(1000)
    assert_not project.can_be_claimed?
  end

  # Class methods
  test "filtered_and_sorted should handle admin access" do
    results = RndProject.filtered_and_sorted(@user)
    assert_equal RndProject.count, results.count
  end

  test "filtered_and_sorted should handle employee access" do
    employee = users(:employee_user)
    results = RndProject.filtered_and_sorted(employee)
    assert_equal RndProject.count, results.count
  end

  test "filtered_and_sorted should handle client access" do
    results = RndProject.filtered_and_sorted(@client)
    assert results.all? { |project| project.client_id == @client.id }
  end

  test "filtered_and_sorted should apply search filter" do
    results = RndProject.filtered_and_sorted(@user, search: "test")
    assert results.all? { |project| 
      project.title.downcase.include?("test") || 
      project.description.downcase.include?("test") 
    }
  end

  test "filtered_and_sorted should apply status filter" do
    results = RndProject.filtered_and_sorted(@user, status_filter: "draft")
    assert results.all? { |project| project.status == "draft" }
  end

  test "filtered_and_sorted should apply client filter" do
    results = RndProject.filtered_and_sorted(@user, client_filter: @client.id)
    assert results.all? { |project| project.client_id == @client.id }
  end
end
