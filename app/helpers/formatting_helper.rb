module FormattingHelper
  def format_date(date, format: "%B %d, %Y")
    return "N/A" if date.nil?
    date.strftime(format)
  end

  def format_datetime(datetime, format: "%B %d, %Y at %I:%M %p")
    return "N/A" if datetime.nil?
    datetime.strftime(format)
  end

  def format_file_size(bytes)
    return "0 Bytes" if bytes.nil? || bytes == 0
    k = 1024
    sizes = ['Bytes', 'KB', 'MB', 'GB']
    i = Math.log(bytes) / Math.log(k)
    "#{sprintf('%.1f', bytes / k**i)} #{sizes[i.floor]}"
  end
end
