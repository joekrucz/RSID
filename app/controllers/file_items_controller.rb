class FileItemsController < ApplicationController
  before_action :require_login
  before_action :set_file_item, only: [:show, :update, :destroy, :download]

  def index
    Rails.logger.info "FileItems accessed by user: #{@current_user.name}"
    
    # Get search and filter parameters
    search = params[:search]&.strip
    category = params[:category]&.strip
    file_type = params[:file_type]&.strip
    sort_by = params[:sort_by] || 'created_at'
    sort_order = params[:sort_order] || 'desc'
    
    files = FileItem.filtered_and_sorted(@current_user, search: search, sort_by: sort_by, sort_order: sort_order)
    
    # Apply additional filters that aren't in the model method yet
    if category.present? && FileItem::CATEGORIES.include?(category)
      files = files.by_category(category)
    end
    
    if file_type.present?
      files = files.by_file_type(file_type)
    end
    
    render inertia: 'FileItems/Index', props: {
      user: user_props,
      files: files.map { |file| file_item_props(file) },
      search: search,
      category: category,
      file_type: file_type,
      sort_by: sort_by,
      sort_order: sort_order,
      categories: FileItem::CATEGORIES,
      file_types: FileItem::FILE_TYPES.keys
    }
  end

  def show
    render inertia: 'FileItems/Show', props: {
      user: user_props,
      file: file_item_props(@file_item)
    }
  end

  def create
    uploaded_file = params[:file]
    
    if uploaded_file.blank?
      render inertia: 'FileItems/Index', props: {
        user: user_props,
        files: @current_user.file_items.recent.map { |file| file_item_props(file) },
        errors: ['Please select a file to upload']
      }
      return
    end
    
    # Create file item
    @file_item = @current_user.file_items.build(file_item_params)
    @file_item.original_filename = uploaded_file.original_filename
    @file_item.content_type = uploaded_file.content_type
    @file_item.file_size = uploaded_file.size
    @file_item.file_type = @file_item.file_type_category
    
    # Save file to storage
    begin
      storage_dir = Rails.root.join('storage', 'uploads', @current_user.id.to_s)
      FileUtils.mkdir_p(storage_dir)
      
      file_path = storage_dir.join(@file_item.safe_filename)
      File.open(file_path, 'wb') do |file|
        file.write(uploaded_file.read)
      end
      
      @file_item.file_path = file_path.to_s
      
      if @file_item.save
        render inertia: 'FileItems/Index', props: {
          user: user_props,
          files: @current_user.file_items.recent.map { |file| file_item_props(file) },
          success_message: "File '#{@file_item.name}' uploaded successfully!"
        }
      else
        # Clean up uploaded file if save failed
        File.delete(file_path) if File.exist?(file_path)
        
        render inertia: 'FileItems/Index', props: {
          user: user_props,
          files: @current_user.file_items.recent.map { |file| file_item_props(file) },
          errors: @file_item.errors.full_messages
        }
      end
    rescue => e
      Rails.logger.error "File upload error: #{e.message}"
      render inertia: 'FileItems/Index', props: {
        user: user_props,
        files: @current_user.file_items.recent.map { |file| file_item_props(file) },
        errors: ['File upload failed. Please try again.']
      }
    end
  end

  def update
    if @file_item.update(file_item_params)
      render inertia: 'FileItems/Index', props: {
        user: user_props,
        files: @current_user.file_items.recent.map { |file| file_item_props(file) },
        success_message: "File '#{@file_item.name}' updated successfully!"
      }
    else
      render inertia: 'FileItems/Index', props: {
        user: user_props,
        files: @current_user.file_items.recent.map { |file| file_item_props(file) },
        errors: @file_item.errors.full_messages
      }
    end
  end

  def destroy
    file_name = @file_item.name
    
    # Delete physical file
    if @file_item.file_path && File.exist?(@file_item.file_path)
      File.delete(@file_item.file_path)
    end
    
    @file_item.destroy
    
    render inertia: 'FileItems/Index', props: {
      user: user_props,
      files: @current_user.file_items.recent.map { |file| file_item_props(file) },
      success_message: "File '#{file_name}' deleted successfully!"
    }
  end

  def download
    if @file_item.file_path && File.exist?(@file_item.file_path)
      send_file @file_item.file_path, 
                filename: @file_item.original_filename,
                type: @file_item.content_type,
                disposition: 'attachment'
    else
      redirect_to file_items_path, alert: 'File not found'
    end
  end

  def preview
    @file_item = @current_user.file_items.find(params[:id])
    
    if @file_item.previewable? && @file_item.file_path && File.exist?(@file_item.file_path)
      case @file_item.file_type_category
      when 'image'
        send_file @file_item.file_path, type: @file_item.content_type, disposition: 'inline'
      when 'pdf'
        send_file @file_item.file_path, type: 'application/pdf', disposition: 'inline'
      when 'text'
        content = File.read(@file_item.file_path)
        render plain: content
      else
        redirect_to file_items_path, alert: 'Preview not available for this file type'
      end
    else
      redirect_to file_items_path, alert: 'Preview not available for this file'
    end
  end

  private

  def set_file_item
    @file_item = @current_user.file_items.find(params[:id])
  end

  def file_item_params
    params.require(:file_item).permit(:name, :description, :category)
  end

  def file_item_props(file)
    {
      id: file.id,
      name: file.name,
      description: file.description,
      original_filename: file.original_filename,
      file_type: file.file_type_category,
      file_size: format_file_size(file.file_size),
      category: file.category,
      content_type: file.content_type,
      previewable: file.previewable?,
      image: file.image?,
      document: file.document?,
      text: file.text?,
      created_at: format_date(file.created_at),
      updated_at: format_date(file.updated_at)
    }
  end
end 