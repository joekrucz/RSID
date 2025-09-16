class GrantDocumentsController < ApplicationController
  before_action :require_login
  before_action :set_grant_application

  # GET /grant_applications/:grant_application_id/grant_documents
  # Optional params: section, title to filter to a checklist item
  def index
    docs = @grant_application.grant_documents
    if params[:section].present? && params[:title].present?
      item = @grant_application.grant_checklist_items.find_by(section: params[:section], title: params[:title])
      docs = docs.where(grant_checklist_item_id: item&.id)
    end
    render json: { success: true, documents: docs.as_json(only: [:id, :name, :file_path, :file_type, :grant_checklist_item_id, :created_at]) }
  end

  # POST /grant_applications/:grant_application_id/grant_documents
  def create
    # Expect multipart form with file and metadata
    section = params[:section]
    title = params[:title]
    item = @grant_application.grant_checklist_items.find_or_create_by(section: section, title: title) if section.present? && title.present?

    uploaded = params[:file]
    unless uploaded.respond_to?(:original_filename)
      return render json: { success: false, error: 'No file uploaded' }, status: :unprocessable_entity
    end

    # Save file under storage/uploads/<grant_application_id>/
    dir = Rails.root.join('storage', 'uploads', @grant_application.id.to_s)
    FileUtils.mkdir_p(dir)
    dest_path = dir.join(uploaded.original_filename)
    File.open(dest_path, 'wb') { |f| f.write(uploaded.read) }

    doc = @grant_application.grant_documents.build(
      name: uploaded.original_filename,
      file_path: dest_path.to_s,
      file_type: File.extname(uploaded.original_filename).delete('.').downcase,
      grant_checklist_item_id: item&.id
    )

    if doc.save
      render json: { success: true, document: doc.as_json }, status: :created
    else
      render json: { success: false, errors: doc.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /grant_applications/:grant_application_id/grant_documents/:id
  def destroy
    doc = @grant_application.grant_documents.find(params[:id])
    begin
      FileUtils.rm_f(doc.file_path) if doc.file_path.present?
    rescue => e
      Rails.logger.warn("Failed to delete file: #{e.message}")
    end
    doc.destroy
    render json: { success: true }
  end

  private

  def set_grant_application
    @grant_application = @current_user.grant_applications.find(params[:grant_application_id])
  end
end


