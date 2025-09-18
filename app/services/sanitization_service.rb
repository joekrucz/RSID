class SanitizationService
  def self.sanitize_search_term(term)
    return "" if term.blank?
    
    # Remove potentially dangerous characters and normalize
    sanitized = term.to_s.strip
      .gsub(/[<>'"&]/, '') # Remove HTML/XML characters
      .gsub(/[;\\]/, '')   # Remove SQL injection characters
      .gsub(/\s+/, ' ')    # Normalize whitespace
      .strip
    
    # Limit length to prevent DoS
    sanitized[0, 100]
  end
  
  def self.sanitize_filename(filename)
    return "" if filename.blank?
    
    # Remove path traversal and dangerous characters
    sanitized = filename.to_s
      .gsub(/[\/\\]/, '_')  # Replace path separators
      .gsub(/[<>:"|?*]/, '_') # Replace Windows forbidden characters
      .gsub(/[^\w\-_\.]/, '_') # Replace non-alphanumeric except - _ .
      .gsub(/_+/, '_')      # Collapse multiple underscores
      .strip
    
    # Ensure it's not empty and has reasonable length
    sanitized.present? ? sanitized[0, 255] : "file"
  end
  
  def self.sanitize_text_input(text)
    return "" if text.blank?
    
    text.to_s.strip
      .gsub(/[<>]/, '') # Remove angle brackets
      .gsub(/\s+/, ' ') # Normalize whitespace
      .strip
  end
end