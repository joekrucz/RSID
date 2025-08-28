class SanitizationService
  class << self
    # Sanitize search queries
    def sanitize_search_query(query)
      return '' if query.blank?
      
      # Remove potentially dangerous characters and limit length
      sanitized = query.to_s.strip
        .gsub(/[<>\"'&]/, '')  # Remove HTML/XML characters
        .gsub(/[^\w\s\-\.]/, '')  # Only allow word chars, spaces, hyphens, dots
        .strip
      
      # Limit length to prevent abuse
      sanitized[0..100]
    end

    # Sanitize text content (notes, messages, etc.)
    def sanitize_text_content(content)
      return '' if content.blank?
      
      # Use Rails' built-in sanitize helper
      ActionController::Base.helpers.sanitize(
        content.to_s,
        tags: %w[p br strong em u ol ul li blockquote],
        attributes: %w[class id]
      )
    end

    # Sanitize file names
    def sanitize_filename(filename)
      return '' if filename.blank?
      
      filename.to_s
        .gsub(/[^\w\-\.]/, '_')  # Replace non-alphanumeric with underscore
        .gsub(/_{2,}/, '_')      # Replace multiple underscores with single
        .strip
    end

    # Sanitize email addresses
    def sanitize_email(email)
      return '' if email.blank?
      
      email.to_s.strip.downcase
    end

    # Validate and sanitize URLs
    def sanitize_url(url)
      return '' if url.blank?
      
      sanitized = url.to_s.strip
      
      # Add protocol if missing
      sanitized = "https://#{sanitized}" unless sanitized.match?(/^https?:\/\//)
      
      # Basic URL validation
      return '' unless sanitized.match?(/^https?:\/\/[^\s]+$/)
      
      sanitized
    end
  end
end
