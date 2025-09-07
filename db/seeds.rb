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

# Demo data: sample grant applications for the first user
if User.exists?(1)
  user = User.find(1)
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
    { title: 'Climate Risk Modelling', description: 'Regional flood risk modelling POC', days_from_now: -5 },
    # Additional demo data
    { title: 'Blockchain Supply Chain', description: 'Transparent supply chain tracking using blockchain', days_from_now: 12 },
    { title: 'VR Training Platform', description: 'Immersive training for industrial workers', days_from_now: 18 },
    { title: 'Smart City Analytics', description: 'Data analytics for urban planning optimization', days_from_now: 25 },
    { title: 'Quantum Computing Research', description: 'Quantum algorithms for optimization problems', days_from_now: 60 },
    { title: 'Autonomous Vehicle Testing', description: 'Self-driving car safety validation platform', days_from_now: 40 },
    { title: 'Renewable Energy Storage', description: 'Advanced battery technology for grid storage', days_from_now: 35 },
    { title: 'Digital Twin Manufacturing', description: 'Virtual replicas for predictive maintenance', days_from_now: 20 },
    { title: 'AI-Powered Drug Discovery', description: 'Machine learning for pharmaceutical research', days_from_now: 50 },
    { title: 'Space Technology Innovation', description: 'Satellite communication optimization', days_from_now: 90 },
    { title: 'Sustainable Agriculture Tech', description: 'Precision farming with IoT sensors', days_from_now: 15 }
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
  
  # Link any existing grant applications that don't have companies
  unlinked_applications = GrantApplication.where(company_id: nil)
  if unlinked_applications.any? && companies.any?
    puts "Linking #{unlinked_applications.count} existing grant applications to companies..."
    unlinked_applications.each do |application|
      random_company = companies.sample
      application.update!(company: random_company)
      puts "  Linked '#{application.title}' to '#{random_company.name}'"
    end
    puts "Successfully linked #{unlinked_applications.count} grant applications to companies!"
  end

  # Ensure ALL grant applications are linked to companies (including newly created ones)
  all_applications = GrantApplication.all
  if all_applications.any? && companies.any?
    unlinked_count = 0
    all_applications.each do |application|
      if application.company_id.nil?
        application.update!(company: companies.sample)
        puts "  Linked '#{application.title}' to '#{application.company.name}'"
        unlinked_count += 1
      end
    end
    if unlinked_count > 0
      puts "Successfully linked #{unlinked_count} additional grant applications to companies!"
    else
      puts "All grant applications are already linked to companies."
    end
  end
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
  { name: 'Wonka Industries', website: 'https://wonka.example', notes: 'Confectionery' },
  # Additional demo companies
  { name: 'TechNova Solutions', website: 'https://technova.example', notes: 'AI & Machine Learning' },
  { name: 'GreenTech Innovations', website: 'https://greentech.example', notes: 'Sustainable Technology' },
  { name: 'Quantum Dynamics', website: 'https://quantum.example', notes: 'Quantum Computing' },
  { name: 'SpaceX Technologies', website: 'https://spacex.example', notes: 'Aerospace & Space' },
  { name: 'BioMed Research', website: 'https://biomed.example', notes: 'Medical Research' },
  { name: 'CyberShield Corp', website: 'https://cybershield.example', notes: 'Cybersecurity' },
  { name: 'DataFlow Systems', website: 'https://dataflow.example', notes: 'Big Data Analytics' },
  { name: 'RoboTech Industries', website: 'https://robotech.example', notes: 'Robotics & Automation' },
  { name: 'CloudScale Inc', website: 'https://cloudscale.example', notes: 'Cloud Infrastructure' },
  { name: 'FinTech Ventures', website: 'https://fintech.example', notes: 'Financial Technology' }
]

sample_companies.each do |c|
  Company.find_or_create_by!(name: c[:name]) do |co|
    co.website = c[:website]
    co.notes = c[:notes]
  end
end

puts 'Seeded sample companies.'
