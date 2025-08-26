class FileItem < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true, length: { minimum: 1, maximum: 255 }
  validates :original_filename, presence: true
  validates :category, inclusion: { in: %w[personal work projects] }
  validates :file_size, numericality: { greater_than: 0 }, allow_nil: true
  validates :user, presence: true
  
  scope :by_user, ->(user) { where(user: user) }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_file_type, ->(file_type) { where(file_type: file_type) }
  scope :recent, -> { order(created_at: :desc) }
  scope :search_by_name, ->(query) { where("name LIKE ? OR description LIKE ?", "%#{query}%", "%#{query}%") }
  
  # File type categories
  FILE_TYPES = {
    'image' => %w[jpg jpeg png gif bmp svg webp],
    'document' => %w[pdf doc docx txt rtf odt],
    'spreadsheet' => %w[xls xlsx csv ods],
    'presentation' => %w[ppt pptx odp],
    'archive' => %w[zip rar 7z tar gz],
    'video' => %w[mp4 avi mov wmv flv webm],
    'audio' => %w[mp3 wav aac ogg flac],
    'code' => %w[js ts jsx tsx rb py java cpp c html css scss sass]
  }.freeze
  
  CATEGORIES = %w[personal work projects].freeze
  
  def file_extension
    original_filename.split('.').last&.downcase
  end
  
  def file_type_category
    ext = file_extension
    FILE_TYPES.each do |category, extensions|
      return category if extensions.include?(ext)
    end
    'other'
  end
  
  def previewable?
    %w[image pdf txt].include?(file_type_category)
  end
  
  def image?
    file_type_category == 'image'
  end
  
  def document?
    file_type_category == 'document'
  end
  
  def text?
    file_type_category == 'text'
  end
  
  def file_size_formatted
    return 'Unknown' unless file_size
    
    units = %w[B KB MB GB TB]
    size = file_size.to_f
    unit_index = 0
    
    while size >= 1024 && unit_index < units.length - 1
      size /= 1024
      unit_index += 1
    end
    
    "#{size.round(1)} #{units[unit_index]}"
  end
  
  def created_at_formatted
    created_at.strftime("%B %d, %Y")
  end
  
  def updated_at_formatted
    updated_at.strftime("%B %d, %Y")
  end
  
  def safe_filename
    # Generate a safe filename for storage
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    safe_name = name.gsub(/[^0-9A-Za-z.\-]/, '_')
    "#{timestamp}_#{safe_name}"
  end
  
  def storage_path
    "uploads/#{user.id}/#{safe_filename}"
  end
end
