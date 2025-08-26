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
  
  def file_size_formatted
    size = file_size
    return "0 B" if size == 0
    
    units = %w[B KB MB GB]
    exp = (Math.log(size) / Math.log(1024)).to_i
    exp = [exp, units.length - 1].min
    
    "%.1f %s" % [size.to_f / 1024**exp, units[exp]]
  end
  
  def icon_class
    case file_type.downcase
    when 'pdf'
      'fas fa-file-pdf text-red-500'
    when 'doc', 'docx'
      'fas fa-file-word text-blue-500'
    when 'xls', 'xlsx'
      'fas fa-file-excel text-green-500'
    when 'ppt', 'pptx'
      'fas fa-file-powerpoint text-orange-500'
    when 'txt'
      'fas fa-file-alt text-gray-500'
    when 'jpg', 'jpeg', 'png', 'gif'
      'fas fa-file-image text-purple-500'
    else
      'fas fa-file text-gray-500'
    end
  end
end
