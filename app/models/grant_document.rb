class GrantDocument < ApplicationRecord
  belongs_to :grant_application
  
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
    return 0 unless File.exist?(file_path)
    File.size(file_path)
  end
  

end
