#!/usr/bin/env ruby
# Comprehensive script to set up production data
# Run this on Railway: rails runner setup_production_data.rb

puts "Setting up production data..."

# First, ensure companies exist
sample_companies = [
  { name: 'Acme Corp', website: 'https://acme.example', notes: 'Manufacturing' },
  { name: 'Globex', website: 'https://globex.example', notes: 'Energy' },
  { name: 'Initech', website: 'https://initech.example', notes: 'Software' },
  { name: 'Umbrella Co', website: 'https://umbrella.example', notes: 'Biotech' },
  { name: 'Soylent Industries', website: 'https://soylent.example', notes: 'Foodtech' },
  { name: 'Hooli', website: 'https://hooli.example', notes: 'Tech conglomerate' },
  { name: 'Stark Industries', website: 'https://stark.example', notes: 'Defense, R&D' },
  { name: 'Wayne Enterprises', website: 'https://wayne.example', notes: 'Diversified' },
  { name: 'Pied Piper', website: 'https://piedpiper.example', notes: 'Compression' },
  { name: 'Wonka Industries', website: 'https://wonka.example', notes: 'Confectionery' }
]

puts "Creating companies..."
sample_companies.each do |c|
  company = Company.find_or_create_by!(name: c[:name]) do |co|
    co.website = c[:website]
    co.notes = c[:notes]
  end
  puts "  Created/Found: #{company.name}"
end

# Get all companies
companies = Company.all
puts "Total companies: #{companies.count}"

# Get all grant applications without companies
unlinked_applications = GrantApplication.where(company_id: nil)

if unlinked_applications.empty?
  puts "All grant applications are already linked to companies."
else
  puts "Found #{unlinked_applications.count} grant applications to link..."
  
  # Link each application to a random company
  unlinked_applications.each do |application|
    random_company = companies.sample
    application.update!(company: random_company)
    puts "  Linked '#{application.title}' to '#{random_company.name}'"
  end
  
  puts "Successfully linked #{unlinked_applications.count} grant applications to companies!"
end

# Show final summary
puts "\nFinal Summary:"
companies.each do |company|
  count = company.grant_applications.count
  puts "  #{company.name}: #{count} grant application(s)"
end

puts "\nSetup complete!"
