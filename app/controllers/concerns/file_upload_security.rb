module FileUploadSecurity
  extend ActiveSupport::Concern

  private

  def secure_file_upload(file)
    # Validate file exists
    raise "No file provided" if file.blank?
    
    # Validate file type
    allowed_types = %w[
      application/pdf
      image/jpeg
      image/jpg
      image/png
      image/gif
      text/plain
      application/msword
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
    ]
    
    unless allowed_types.include?(file.content_type)
      raise "Invalid file type. Allowed types: #{allowed_types.join(', ')}"
    end
    
    # Validate file size (10MB max)
    max_size = 10.megabytes
    if file.size > max_size
      raise "File too large. Maximum size is #{max_size / 1.megabyte}MB"
    end
    
    # Sanitize filename
    sanitized_name = SanitizationService.sanitize_filename(file.original_filename)
    
    # Add timestamp to prevent conflicts
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    final_filename = "#{timestamp}_#{sanitized_name}"
    
    # Return file with sanitized name
    file.tap { |f| f.define_singleton_method(:original_filename) { final_filename } }
  end
  
  def validate_file_extension(filename, allowed_extensions)
    return false if filename.blank?
    
    extension = File.extname(filename).downcase
    allowed_extensions.include?(extension)
  end
  
  def scan_file_for_malicious_content(file)
    # Basic content validation
    content = file.read(1024) # Read first 1KB
    
    # Check for executable signatures
    executable_signatures = [
      "\x4D\x5A", # PE executable
      "\x7F\x45\x4C\x46", # ELF executable
      "\xFE\xED\xFA", # Mach-O executable
    ]
    
    executable_signatures.each do |signature|
      if content.start_with?(signature)
        raise "File appears to be an executable, which is not allowed"
      end
    end
    
    # Reset file pointer
    file.rewind
  end
end
