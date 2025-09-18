# GrantApplicationPresenter
# 
# Handles all presentation logic for grant applications.
# Extracted from GrantApplicationsController to follow Single Responsibility Principle.
class GrantApplicationPresenter
  include ActionView::Helpers::TextHelper
  include ApplicationHelper

  def initialize(grant_application)
    @grant_application = grant_application
  end

  def self.index_props(applications, user, search_result)
    {
      user: PropsBuilderService.user_props(user),
      grant_applications: applications.map { |app| new(app).index_props },
      pipeline_data: build_pipeline_data(search_result[:pipeline_data]),
      filters: {
        search: search_result[:search],
        per_page: search_result[:per_page]
      },
      pagination: build_pagination_props(search_result),
      stats: build_stats_props(user),
      view_mode: search_result[:view_mode] || 'list'
    }
  end

  def self.show_props(grant_application, user)
    {
      user: PropsBuilderService.user_props(user),
      grant_application: new(grant_application).index_props,
      checklist_items: grant_application.grant_checklist_items.order(:section, :title).map { |i| new(grant_application).checklist_item_props(i) },
      documents: grant_application.grant_documents.map { |doc| new(grant_application).document_props(doc) }
    }
  end

  def self.new_props(user, grant_application = nil)
    {
      user: PropsBuilderService.user_props(user),
      companies: Company.all.order(:name).map { |c| new(grant_application).company_props(c) },
      competitions: GrantCompetition.all.order(:deadline).map { |c| new(grant_application).competition_props(c) },
      errors: grant_application&.errors,
      grant_application: grant_application&.attributes
    }
  end

  def self.edit_props(grant_application, user)
    {
      user: PropsBuilderService.user_props(user),
      grant_application: new(grant_application).index_props,
      companies: Company.all.order(:name).map { |c| new(grant_application).company_props(c) },
      competitions: GrantCompetition.all.order(:deadline).map { |c| new(grant_application).competition_props(c) },
      errors: grant_application.errors.full_messages
    }
  end

  def index_props
    {
      id: @grant_application.id,
      title: @grant_application.title,
      description: @grant_application.description,
      stage: @grant_application.stage,
      stage_badge_class: grant_stage_badge_class(@grant_application.stage),
      days_until_deadline: @grant_application.days_until_deadline,
      overdue: @grant_application.overdue?,
      can_edit: @grant_application.can_edit?,
      can_submit: @grant_application.can_submit?,
      created_at: @grant_application.created_at.strftime("%B %d, %Y"),
      updated_at: @grant_application.updated_at.strftime("%B %d, %Y"),
      documents_count: @grant_application.grant_documents.count,
      company: @grant_application.company ? company_props(@grant_application.company) : nil,
      grant_competition: @grant_application.grant_competition ? competition_props(@grant_application.grant_competition) : nil,
      manual_stage_override: @grant_application.manual_stage_override?,
      stage_conflict: @grant_application.stage_conflict?,
      stage_conflict_message: @grant_application.stage_conflict_message,
      stage_conflict_details: @grant_application.stage_conflict_details,
      automatic_stage: @grant_application.automatic_stage,
      qualification_cost_pence: @grant_application.qualification_cost_pence
    }
  end

  def checklist_item_props(item)
    {
      id: item.id,
      section: item.section,
      title: item.title,
      due_date: item.due_date&.strftime('%Y-%m-%d'),
      checked: item.checked,
      technical_qualifier: item.technical_qualifier,
      no_technical_qualifier: item.no_technical_qualifier,
      contract_link: item.contract_link,
      review_delivered_on: item.review_delivered_on&.strftime('%Y-%m-%d'),
      invoice_sent_on: item.invoice_sent_on&.strftime('%Y-%m-%d'),
      invoice_paid_on: item.invoice_paid_on&.strftime('%Y-%m-%d'),
      resourced_subcontractor: item.resourced_subcontractor,
      delivery_folder_link: item.delivery_folder_link,
      slack_channel_name: item.slack_channel_name,
      resub_due: item.resub_due,
      eligibility_check_cost_pence: item.eligibility_check_cost_pence,
      deal_outcome: item.deal_outcome,
      completed_at: item.completed_at&.iso8601,
      notes: item.notes
    }
  end

  def document_props(document)
    {
      id: document.id,
      name: document.name,
      file_type: document.file_type,
      file_size: format_file_size(document.file_size),
      icon_class: document.icon_class,
      created_at: document.created_at.strftime("%B %d, %Y")
    }
  end

  def company_props(company)
    # Format company data for presentation
    {
      id: company.id,
      name: company.name,
      website: company.website,
      notes: company.notes
    }
  end

  def competition_props(competition)
    {
      id: competition.id,
      grant_name: competition.grant_name,
      deadline: competition.deadline,
      funding_body: competition.funding_body,
      competition_link: competition.competition_link,
      status: competition.status,
      upcoming: competition.upcoming?,
      past: competition.past?,
      days_until_deadline: competition.days_until_deadline
    }
  end

  private

  def self.build_pagination_props(search_result)
    per_page = search_result[:per_page]
    total_count = search_result[:total_count]
    current_page = search_result[:applications].current_page
    total_pages = search_result[:applications].total_pages

    {
      current_page: current_page,
      total_pages: total_pages,
      per_page: per_page,
      total_count: total_count,
      has_next_page: search_result[:applications].next_page.present?,
      has_prev_page: search_result[:applications].prev_page.present?
    }
  end

  def self.build_stats_props(user)
    {
      total: user.grant_applications.count,
      overdue: user.grant_applications.overdue.count
    }
  end

  def self.build_pipeline_data(pipeline_data)
    formatted_pipeline_data = {}
    pipeline_data.each do |stage, data|
      formatted_pipeline_data[stage] = {
        applications: data[:applications].map { |app| new(app).index_props },
        count: data[:count],
        total_value: data[:total_value]
      }
    end
    formatted_pipeline_data
  end
end
