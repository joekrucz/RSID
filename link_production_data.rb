#!/usr/bin/env ruby
# Script to link grant applications to companies in production
# Run this on Railway: rails runner link_production_data.rb

puts "Starting to link grant applications to companies..."

# Get all companies
companies = Company.all
if companies.empty?
  puts "No companies found. Please run db:seed first to create companies."
  exit
end

# Get all grant applications without companies
unlinked_applications = GrantApplication.where(company_id: nil)

if unlinked_applications.empty?
  puts "All grant applications are already linked to companies."
  exit
end

puts "Found #{unlinked_applications.count} grant applications to link..."

# Link each application to a random company
unlinked_applications.each do |application|
  random_company = companies.sample
  application.update!(company: random_company)
  puts "Linked '#{application.title}' to '#{random_company.name}'"
end

puts "Successfully linked #{unlinked_applications.count} grant applications to companies!"

# Show summary
puts "\nSummary:"
companies.each do |company|
  count = company.grant_applications.count
  puts "  #{company.name}: #{count} grant application(s)"
end
