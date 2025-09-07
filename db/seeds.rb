# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create default feature flags
default_features = [
  {
    name: 'rnd_projects',
    description: 'R&D Project Management - Create, view, edit, and delete R&D projects',
    enabled: true,
    settings: { employee_enabled: true, client_enabled: true }
  },
  {
    name: 'grant_applications',
    description: 'Grant Application Management - Manage grant applications and documentation',
    enabled: true,
    settings: { employee_enabled: true, client_enabled: false }
  },
  {
    name: 'advanced_analytics',
    description: 'Advanced Dashboard Analytics - Detailed reporting and insights',
    enabled: false,
    settings: { employee_enabled: true, client_enabled: false }
  },
  {
    name: 'document_management',
    description: 'Document Upload and Management - File storage and organization',
    enabled: false,
    settings: { employee_enabled: true, client_enabled: false }
  },
  {
    name: 'api_access',
    description: 'API Access for Integrations - External API access',
    enabled: false,
    settings: { employee_enabled: true, client_enabled: false }
  },
  {
    name: 'messaging',
    description: 'Internal Messaging System - Communication between users',
    enabled: true,
    settings: { employee_enabled: true, client_enabled: false }
  }
]

default_features.each do |feature|
  FeatureFlag.find_or_create_by(name: feature[:name]) do |flag|
    flag.description = feature[:description]
    flag.enabled = feature[:enabled]
    flag.settings = feature[:settings]
  end
end

puts "Created #{default_features.length} feature flags"

# Create demo admin user if no users exist
unless User.exists?
  admin_user = User.create!(
    name: "Demo Admin",
    email: "admin@demo.com",
    password: "password123",
    password_confirmation: "password123",
    role: :admin
  )
  puts "Created demo admin user: admin@demo.com / password123"
end

# Demo data: sample grant applications for the admin user
admin_user = User.find_by(email: 'admin@demo.com')
if admin_user
  user = admin_user
  samples = [
    { title: 'AI Research Grant', description: 'Funding to develop AI-driven insights for SMEs', days_from_now: 7 },
    { title: 'Green Energy Initiative', description: 'Solar microgrid feasibility study', days_from_now: 14 },
    { title: 'Healthcare Data Platform', description: 'Interoperable patient data platform MVP', days_from_now: 3 },
    { title: 'EdTech Pilot Programme', description: 'Adaptive learning for secondary schools', days_from_now: 30 },
    { title: 'AgriTech Sensor Network', description: 'Soil monitoring IoT rollout', days_from_now: -2 },
    { title: 'Cybersecurity Toolkit', description: 'SME cyber posture automation', days_from_now: 21 },
    { title: 'Urban Mobility Study', description: 'EV charging optimization research', days_from_now: 10 },
    { title: 'Manufacturing Robotics', description: 'Cobots for assembly line improvements', days_from_now: 5 },
    { title: 'FinTech Compliance Engine', description: 'Automated AML/KYC screening MVP', days_from_now: 45 },
    { title: 'Climate Risk Modelling', description: 'Regional flood risk modelling POC', days_from_now: -5 }
  ]

  # Get companies for assignment
  companies = Company.all
  
  samples.each_with_index do |s, i|
    deadline = Time.current + s[:days_from_now].days
    GrantApplication.find_or_create_by!(user: user, title: s[:title]) do |ga|
      ga.description = s[:description]
      ga.deadline = deadline
      ga.stage = GrantApplication.stages.keys.sample if GrantApplication.respond_to?(:stages)
      # Assign a random company to each application
      ga.company = companies.sample if companies.any?
    end
  end

  puts 'Seeded sample grant applications for demo.'
else
  puts 'No user with id=1 found. Skipping demo grant applications.'
end

# Demo data: sample companies
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

sample_companies.each do |c|
  Company.find_or_create_by!(name: c[:name]) do |co|
    co.website = c[:website]
    co.notes = c[:notes]
  end
end

puts 'Seeded sample companies.'
