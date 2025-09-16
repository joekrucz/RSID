class GrantDocument < ApplicationRecord
  belongs_to :grant_application
  # Optional linkage to a specific checklist item
  attribute :section, :string
  attribute :item_title, :string
  
  validates :name, presence: true, length: { minimum: 1, maximum: 255 }
  validates :file_path, presence: true
  validates :file_type, presence: true
  
  # File type validation
  validates :file_type, inclusion: { 
    in: %w[pdf doc docx xls xlsx ppt pptx txt jpg jpeg png gif],
    message: "must be a valid file type" 
  }
  
  # Helper methods
  def file_extension
    File.extname(file_path).downcase[1..-1]
  end
  
  def file_size
    path = file_system_path
    return 0 unless File.exist?(path)
    File.size(path)
  end
  
  def file_system_path
    if file_path.to_s.start_with?('/')
      Rails.root.join('public', file_path.sub(%r{^/}, '')).to_s
    else
      file_path.to_s
    end
  end

  def icon_class
    case file_extension
    when 'pdf' then 'i-ph-file-pdf text-error'
    when 'doc', 'docx' then 'i-ph-file-doc text-primary'
    when 'xls', 'xlsx' then 'i-ph-file-xls text-success'
    when 'ppt', 'pptx' then 'i-ph-file-ppt text-warning'
    when 'jpg', 'jpeg', 'png', 'gif' then 'i-ph-file-image text-accent'
    when 'txt' then 'i-ph-file-text'
    else 'i-ph-file'
    end
  end

end
