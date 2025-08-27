require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  include ApplicationHelper

  # Date formatting tests
  test "format_date should format date correctly" do
    date = Date.new(2025, 8, 26)
    assert_equal "August 26, 2025", format_date(date)
  end

  test "format_date should handle custom format" do
    date = Date.new(2025, 8, 26)
    assert_equal "26/08/2025", format_date(date, format: "%d/%m/%Y")
  end

  test "format_date should return N/A for nil date" do
    assert_equal "N/A", format_date(nil)
  end

  test "format_datetime should format datetime correctly" do
    datetime = DateTime.new(2025, 8, 26, 14, 30, 0)
    assert_equal "August 26, 2025 at 02:30 PM", format_datetime(datetime)
  end

  test "format_datetime should handle custom format" do
    datetime = DateTime.new(2025, 8, 26, 14, 30, 0)
    assert_equal "26/08/2025 14:30", format_datetime(datetime, format: "%d/%m/%Y %H:%M")
  end

  test "format_datetime should return N/A for nil datetime" do
    assert_equal "N/A", format_datetime(nil)
  end

  test "format_due_date should format due date correctly" do
    due_date = Date.new(2025, 8, 26)
    assert_equal "August 26, 2025", format_due_date(due_date)
  end

  test "format_due_date should return default message for nil" do
    assert_equal "No due date set", format_due_date(nil)
  end

  # File size formatting tests
  test "format_file_size should format bytes correctly" do
    assert_equal "1024.0 B", format_file_size(1024)
  end

  test "format_file_size should format kilobytes correctly" do
    assert_equal "1.0 KB", format_file_size(1024 * 1024)
  end

  test "format_file_size should format megabytes correctly" do
    assert_equal "1.0 MB", format_file_size(1024 * 1024 * 1024)
  end

  test "format_file_size should format gigabytes correctly" do
    assert_equal "1.0 GB", format_file_size(1024 * 1024 * 1024 * 1024)
  end

  test "format_file_size should handle decimal values" do
    assert_equal "1.5 KB", format_file_size(1536)
  end

  test "format_file_size should return Unknown for nil" do
    assert_equal "Unknown", format_file_size(nil)
  end

  # Status color tests
  test "grant_application_status_color should return correct colors" do
    assert_equal "badge-neutral", grant_application_status_color("draft")
    assert_equal "badge-info", grant_application_status_color("submitted")
    assert_equal "badge-warning", grant_application_status_color("under_review")
    assert_equal "badge-success", grant_application_status_color("approved")
    assert_equal "badge-error", grant_application_status_color("rejected")
    assert_equal "badge-success", grant_application_status_color("completed")
    assert_equal "badge-neutral", grant_application_status_color("unknown")
  end

  test "rnd_project_status_color should return correct colors" do
    assert_equal "badge-neutral", rnd_project_status_color("draft")
    assert_equal "badge-info", rnd_project_status_color("active")
    assert_equal "badge-success", rnd_project_status_color("completed")
    assert_equal "badge-warning", rnd_project_status_color("ready_for_claim")
    assert_equal "badge-neutral", rnd_project_status_color("unknown")
  end

  test "todo_priority_color should return correct colors" do
    assert_equal "badge-error", todo_priority_color("high")
    assert_equal "badge-warning", todo_priority_color("medium")
    assert_equal "badge-success", todo_priority_color("low")
    assert_equal "badge-neutral", todo_priority_color("unknown")
  end

  # Status display name tests
  test "grant_application_status_display should format status correctly" do
    assert_equal "Draft", grant_application_status_display("draft")
    assert_equal "Under Review", grant_application_status_display("under_review")
    assert_equal "Ready For Claim", grant_application_status_display("ready_for_claim")
  end

  test "rnd_project_status_display should format status correctly" do
    assert_equal "Draft", rnd_project_status_display("draft")
    assert_equal "Under Review", rnd_project_status_display("under_review")
    assert_equal "Ready For Claim", rnd_project_status_display("ready_for_claim")
  end

  # File type icon tests
  test "file_type_icon should return correct icons" do
    assert_equal "fas fa-file-pdf text-red-500", file_type_icon("pdf")
    assert_equal "fas fa-file-word text-blue-500", file_type_icon("doc")
    assert_equal "fas fa-file-word text-blue-500", file_type_icon("docx")
    assert_equal "fas fa-file-excel text-green-500", file_type_icon("xls")
    assert_equal "fas fa-file-excel text-green-500", file_type_icon("xlsx")
    assert_equal "fas fa-file-powerpoint text-orange-500", file_type_icon("ppt")
    assert_equal "fas fa-file-powerpoint text-orange-500", file_type_icon("pptx")
    assert_equal "fas fa-file-alt text-gray-500", file_type_icon("txt")
    assert_equal "fas fa-file-image text-purple-500", file_type_icon("jpg")
    assert_equal "fas fa-file-image text-purple-500", file_type_icon("png")
    assert_equal "fas fa-file text-gray-500", file_type_icon("unknown")
  end

  test "file_type_icon should handle case insensitive" do
    assert_equal "fas fa-file-pdf text-red-500", file_type_icon("PDF")
    assert_equal "fas fa-file-word text-blue-500", file_type_icon("DOC")
  end

  test "file_type_icon should handle nil" do
    assert_equal "fas fa-file text-gray-500", file_type_icon(nil)
  end
end
