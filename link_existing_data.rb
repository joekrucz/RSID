# link_existing_data.rb
puts "Linking existing grant applications to companies..."

companies = Company.all
if companies.empty?
  puts "No companies found. Please ensure companies exist before running this script."
  exit
end

all_applications = GrantApplication.all
if all_applications.empty?
  puts "No grant applications found."
  exit
end

unlinked_count = 0
all_applications.each do |application|
  if application.company_id.nil?
    application.update!(company: companies.sample)
    puts "  Linked '#{application.title}' to '#{application.company.name}'"
    unlinked_count += 1
  end
end

if unlinked_count > 0
  puts "Successfully linked #{unlinked_count} grant applications to companies!"
else
  puts "All grant applications are already linked to companies."
end

puts "\nFinal Summary:"
companies.each do |company|
  puts "  #{company.name}: #{company.grant_applications.count} grant application(s)"
end
