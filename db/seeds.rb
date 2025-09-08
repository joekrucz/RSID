# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create default feature flags
default_features = [
  {
    name: 'rnd_claims',
    description: 'R&D Claim Management - Create, view, edit, and delete R&D claims',
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
      # Choose a stage and create matching checklist items
      stage_keys = GrantApplication.stages.keys
      chosen_stage = stage_keys.sample
      ga.stage = chosen_stage if GrantApplication.respond_to?(:stages)
      # Assign a random company to each application
      ga.company = companies.sample if companies.any?
    end
    # Ensure checklist items reflect the current stage
    app = GrantApplication.find_by!(user: user, title: s[:title])
    stage_index = GrantApplication.stages[app.stage]
    section_order = [
      'Client Acquisition/Project Qualification',
      'Client Invoiced',
      'Invoice Paid',
      'Preparing for Kick Off/AML/Resourcing',
      'Kicked Off/In Progress',
      'Submitted',
      'Awaiting Funding Decision',
      'Application Successful/Not Successful',
      'Resub Due',
      'Success Fee Invoiced',
      'Success Fee Paid'
    ]
    section_items = {
      'Client Acquisition/Project Qualification' => [
        'Project Qualification',
        'Proposal Presented',
        'Agreement Sent',
        'New Project Handover Sent To Delivery',
        'Deal marked as "won" / "lost"'
      ],
      'Client Invoiced' => ['Invoice Sent'],
      'Invoice Paid' => ['Payment Received'],
      'Preparing for Kick Off/AML/Resourcing' => [
        'AML Checks Completed',
        'Project Resourced',
        'Project Set Up - Slack Channel, Delivery Folders, Etc.'
      ],
      'Kicked Off/In Progress' => [
        'Kick Off Call Confirmed',
        'Timeline Confirmed and Accepted by Client',
        'Drafting',
        'Reviews Confirmed',
        'Eligibility Checks Completed'
      ],
      'Submitted' => ['Application Submitted'],
      'Awaiting Funding Decision' => ['Completed'],
      'Application Successful/Not Successful' => ['Completed'],
      'Resub Due' => ['Completed'],
      'Success Fee Invoiced' => ['Completed'],
      'Success Fee Paid' => ['Completed']
    }
    section_order.each_with_index do |section, idx|
      (section_items[section] || []).each do |title|
        item = app.grant_checklist_items.find_or_initialize_by(section: section, title: title)
        item.checked = idx <= stage_index
        item.save!
      end
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

# Create grant competitions for demo
if User.exists?(1)
  user = User.find(1)
  puts 'Creating grant competitions...'
  
  # Create 20 grant competitions
  competitions = []
  funding_bodies = [
    'Innovate UK',
    'UK Research and Innovation (UKRI)',
    'Department for Business, Energy & Industrial Strategy',
    'National Institute for Health Research',
    'Engineering and Physical Sciences Research Council',
    'Biotechnology and Biological Sciences Research Council',
    'Economic and Social Research Council',
    'Arts and Humanities Research Council',
    'Medical Research Council',
    'Natural Environment Research Council',
    'Science and Technology Facilities Council',
    'Department for Education',
    'Department for Transport',
    'Department for Environment, Food and Rural Affairs',
    'Department of Health and Social Care',
    'Ministry of Defence',
    'Department for Digital, Culture, Media and Sport',
    'Department for International Trade',
    'Department for Levelling Up, Housing and Communities',
    'Department for Work and Pensions'
  ]
  
  grant_types = [
    'Innovation Grant',
    'Research and Development Grant',
    'Technology Transfer Grant',
    'Collaborative Research Grant',
    'Feasibility Study Grant',
    'Proof of Concept Grant',
    'Scale-up Grant',
    'International Collaboration Grant',
    'SME Innovation Grant',
    'Academic Research Grant',
    'Industrial Research Grant',
    'Technology Innovation Grant',
    'Digital Transformation Grant',
    'Sustainability Innovation Grant',
    'Healthcare Innovation Grant',
    'Education Technology Grant',
    'Clean Energy Grant',
    'Advanced Manufacturing Grant',
    'Artificial Intelligence Grant',
    'Cybersecurity Innovation Grant'
  ]
  
  (1..20).each do |i|
    competition = GrantCompetition.find_or_create_by!(
      grant_name: "#{grant_types.sample} #{i}"
    ) do |comp|
      comp.funding_body = funding_bodies.sample
      comp.deadline = rand(30..365).days.from_now
      comp.competition_link = "https://example.com/competition/#{i}"
    end
    competitions << competition
  end

  puts "Created #{competitions.length} grant competitions"
  
  # Link all existing grant applications to competitions
  GrantApplication.where(grant_competition_id: nil).find_each do |app|
    app.update!(grant_competition: competitions.sample)
  end

  puts "Linked all existing grant applications to competitions"
  puts "Total competitions: #{GrantCompetition.count}"
end

# Add 100 additional companies and applications for comprehensive demo data
if User.exists?(1)
  user = User.find(1)
  
  # Create 100 additional companies
  additional_company_names = [
    'Quantum Computing Corp', 'Neural Networks Inc', 'Blockchain Solutions Ltd', 'Robotics Dynamics', 'Green Energy Systems',
    'Data Analytics Pro', 'Cloud Infrastructure Co', 'Mobile App Innovations', 'AI Healthcare Solutions', 'FinTech Revolution',
    'Space Technology Ltd', 'Biotech Research Group', 'Cyber Security Experts', 'IoT Development Co', 'Machine Learning Labs',
    'Virtual Reality Studios', 'Augmented Reality Tech', 'Edge Computing Solutions', '5G Network Systems', 'Smart City Technologies',
    'Autonomous Vehicles Inc', 'Drone Technology Corp', 'Renewable Energy Co', 'Carbon Capture Systems', 'Water Purification Tech',
    'Food Security Solutions', 'Agricultural Automation', 'Precision Medicine Labs', 'Gene Therapy Research', 'Drug Discovery Systems',
    'Wearable Technology Co', 'Smart Home Solutions', 'Digital Twin Systems', 'Predictive Analytics Inc', 'Real-time Processing Co',
    'Distributed Computing Ltd', 'Microservices Architecture', 'API Gateway Solutions', 'Database Optimization Co', 'Cache Management Systems',
    'Load Balancing Tech', 'Container Orchestration', 'Serverless Computing Co', 'Event Streaming Systems', 'Message Queue Solutions',
    'Search Engine Optimization', 'Content Delivery Networks', 'CDN Acceleration Co', 'Web Performance Labs', 'User Experience Design',
    'Advanced Materials Corp', 'Nano Technology Inc', 'Biomimetic Solutions', 'Synthetic Biology Labs', 'Clean Energy Ventures',
    'Carbon Neutral Tech', 'Circular Economy Co', 'Sustainable Manufacturing', 'Green Chemistry Labs', 'Environmental Monitoring',
    'Climate Adaptation Tech', 'Resilience Engineering', 'Disaster Recovery Systems', 'Emergency Response Tech', 'Public Safety Solutions',
    'Smart Grid Technologies', 'Energy Storage Systems', 'Power Management Co', 'Electrical Infrastructure', 'Renewable Integration',
    'Hydrogen Fuel Cells', 'Solar Panel Innovations', 'Wind Energy Systems', 'Geothermal Solutions', 'Tidal Power Technologies',
    'Nuclear Fusion Research', 'Advanced Reactor Design', 'Waste Management Tech', 'Recycling Automation', 'Resource Recovery Systems',
    'Water Treatment Solutions', 'Desalination Technology', 'Aquaculture Systems', 'Marine Conservation Tech', 'Ocean Energy Harvesting',
    'Space Mining Ventures', 'Asteroid Resources Inc', 'Lunar Base Technologies', 'Mars Colonization Co', 'Interplanetary Transport',
    'Satellite Constellation', 'Space Debris Cleanup', 'Orbital Manufacturing', 'Space Tourism Tech', 'Zero Gravity Research',
    'Advanced Propulsion', 'Hypersonic Vehicles', 'Electric Aircraft', 'Urban Air Mobility', 'Flying Car Technologies',
    'Hyperloop Systems', 'Maglev Transportation', 'Autonomous Shipping', 'Smart Ports Tech', 'Logistics Optimization'
  ]

  created_companies = []
  additional_company_names.each do |name|
    company = Company.find_or_create_by!(name: name) do |c|
      c.website = "https://#{name.downcase.gsub(/\s+/, '')}.com"
      c.notes = "Demo company for #{name}"
    end
    created_companies << company
  end

  puts "Created #{created_companies.length} additional companies"

  # Create 100 additional grant applications linked to the newly created companies
  additional_application_titles = [
    'Quantum Algorithm Development', 'Neural Network Optimization', 'Blockchain Security Protocol', 'Robotic Process Automation', 'Green Energy Storage',
    'Big Data Analytics Platform', 'Cloud Migration Strategy', 'Mobile Payment System', 'AI Diagnostic Tools', 'Digital Banking Solutions',
    'Satellite Communication Tech', 'Gene Editing Research', 'Network Security Framework', 'Smart Sensor Networks', 'Deep Learning Models',
    'VR Training Simulations', 'AR Navigation Systems', 'Edge AI Processing', '5G Infrastructure', 'Smart Traffic Management',
    'Self-Driving Car Software', 'Drone Delivery Network', 'Solar Panel Efficiency', 'Carbon Neutral Technology', 'Water Treatment Systems',
    'Vertical Farming Solutions', 'Precision Agriculture', 'Personalized Medicine', 'Gene Therapy Delivery', 'Drug Testing Automation',
    'Health Monitoring Devices', 'Smart Building Controls', 'Digital Twin Platform', 'Predictive Maintenance', 'Real-time Data Processing',
    'Distributed Database Systems', 'Microservices Architecture', 'API Management Platform', 'Database Performance Tuning', 'Intelligent Caching',
    'Load Distribution Algorithms', 'Container Management', 'Serverless Functions', 'Event Processing Engine', 'Message Queue Optimization',
    'Search Algorithm Enhancement', 'Content Distribution', 'CDN Performance', 'Web Speed Optimization', 'UX Research Platform',
    'Advanced Material Synthesis', 'Nano Manufacturing Process', 'Biomimetic Design Systems', 'Synthetic Organism Development', 'Clean Energy Storage',
    'Carbon Capture Technology', 'Circular Economy Platform', 'Sustainable Production Methods', 'Green Chemical Processes', 'Environmental Sensing',
    'Climate Modeling Software', 'Resilience Assessment Tools', 'Disaster Prediction Systems', 'Emergency Communication Tech', 'Public Safety Analytics',
    'Smart Grid Management', 'Energy Storage Optimization', 'Power Distribution Control', 'Grid Integration Solutions', 'Renewable Energy Storage',
    'Hydrogen Production Systems', 'Solar Efficiency Enhancement', 'Wind Turbine Optimization', 'Geothermal Energy Extraction', 'Tidal Power Generation',
    'Fusion Reactor Design', 'Advanced Nuclear Safety', 'Waste Processing Technology', 'Recycling Automation Systems', 'Resource Extraction Methods',
    'Water Purification Systems', 'Desalination Technology', 'Aquaculture Management', 'Marine Ecosystem Monitoring', 'Ocean Energy Conversion',
    'Space Resource Mining', 'Asteroid Processing Technology', 'Lunar Habitat Systems', 'Mars Settlement Infrastructure', 'Interplanetary Transport Systems',
    'Satellite Network Management', 'Space Debris Removal', 'Orbital Manufacturing Systems', 'Space Tourism Infrastructure', 'Zero Gravity Research',
    'Advanced Propulsion Systems', 'Hypersonic Vehicle Design', 'Electric Aircraft Technology', 'Urban Air Mobility Solutions', 'Flying Vehicle Systems',
    'Hyperloop Transportation', 'Maglev Train Technology', 'Autonomous Shipping Systems', 'Smart Port Operations', 'Logistics Optimization Platform'
  ]

  created_applications = []
  additional_application_titles.each_with_index do |title, index|
    deadline = Time.current + rand(1..90).days
    # Link each application to a corresponding newly created company
    company = created_companies[index % created_companies.length]

    application = GrantApplication.find_or_create_by!(user: user, title: title) do |app|
      app.description = "Advanced research and development project for #{title}"
      app.deadline = deadline
      app.stage = GrantApplication.stages.keys.sample
      app.company = company
      app.grant_competition = GrantCompetition.all.sample
    end
    created_applications << application

    # Ensure checklist items and stage are in sync with varying completion
    stage_keys = GrantApplication.stages.keys
    # Choose a target stage index for demo variety
    desired_stage_index = GrantApplication.stages[application.stage] || rand(0..(stage_keys.length - 1))
    application.update!(stage: stage_keys[desired_stage_index])

    section_order = [
      'Client Acquisition/Project Qualification',
      'Client Invoiced',
      'Invoice Paid',
      'Preparing for Kick Off/AML/Resourcing',
      'Kicked Off/In Progress',
      'Submitted',
      'Awaiting Funding Decision',
      'Application Successful/Not Successful',
      'Resub Due',
      'Success Fee Invoiced',
      'Success Fee Paid'
    ]
    section_items = {
      'Client Acquisition/Project Qualification' => [
        'Project Qualification',
        'Proposal Presented',
        'Agreement Sent',
        'New Project Handover Sent To Delivery',
        'Deal marked as "won" / "lost"'
      ],
      'Client Invoiced' => ['Invoice Sent'],
      'Invoice Paid' => ['Payment Received'],
      'Preparing for Kick Off/AML/Resourcing' => [
        'AML Checks Completed',
        'Project Resourced',
        'Project Set Up - Slack Channel, Delivery Folders, Etc.'
      ],
      'Kicked Off/In Progress' => [
        'Kick Off Call Confirmed',
        'Timeline Confirmed and Accepted by Client',
        'Drafting',
        'Reviews Confirmed',
        'Eligibility Checks Completed'
      ],
      'Submitted' => ['Application Submitted'],
      'Awaiting Funding Decision' => ['Completed'],
      'Application Successful/Not Successful' => ['Completed'],
      'Resub Due' => ['Completed'],
      'Success Fee Invoiced' => ['Completed'],
      'Success Fee Paid' => ['Completed']
    }

    section_order.each_with_index do |section, idx|
      (section_items[section] || []).each do |task_title|
        item = application.grant_checklist_items.find_or_initialize_by(section: section, title: task_title)
        # Mark items checked for all sections strictly before the desired stage index
        # Leave the desired section and subsequent sections unchecked for realism
        item.checked = idx < desired_stage_index
        item.save!
      end
    end
  end

  puts "Created #{created_applications.length} additional grant applications"
  puts "All applications are linked to companies"
  puts "Total companies: #{Company.count}"
  puts "Total grant applications: #{GrantApplication.count}"
  
  # Create R&D Claims for each company
  puts "\nCreating R&D Claims for each company..."
  
  fiscal_years = ['FY22', 'FY23', 'FY24']
  created_claims = []
  
  Company.all.each_with_index do |company, index|
    fiscal_year = fiscal_years[index % fiscal_years.length]
    claim_title = "#{fiscal_year} R&D Claim"
    
    # Create start and end dates based on fiscal year
    case fiscal_year
    when 'FY22'
      start_date = Date.new(2022, 4, 1)  # April 1, 2022
      end_date = Date.new(2023, 3, 31)   # March 31, 2023
    when 'FY23'
      start_date = Date.new(2023, 4, 1)  # April 1, 2023
      end_date = Date.new(2024, 3, 31)   # March 31, 2024
    when 'FY24'
      start_date = Date.new(2024, 4, 1)  # April 1, 2024
      end_date = Date.new(2025, 3, 31)   # March 31, 2025
    end
    
    claim = RndClaim.find_or_create_by!(company: company, title: claim_title) do |c|
      c.start_date = start_date
      c.end_date = end_date
      # Use the same rich distribution in all environments so prod matches local demo look
      c.stage = ['upcoming', 'readying_for_delivery', 'in_progress', 'finalised', 'filed_awaiting_hmrc', 'claim_processed', 'client_invoiced', 'paid'].sample
      c.qualifying_activities = [
        "Software development and testing",
        "Prototype development and validation",
        "Technical research and analysis",
        "Process improvement and optimization",
        "Innovation and product development"
      ].sample(rand(2..4)).join(", ")
      c.technical_challenges = [
        "Scalability and performance optimization",
        "Integration with existing systems",
        "Data security and compliance requirements",
        "User experience and interface design",
        "Algorithm development and optimization"
      ].sample(rand(2..3)).join(", ")
      
      # CNF status and deadline
      cnf_statuses = ['not_claiming', 'cnf_needed', 'cnf_exemption_possible', 'in_progress', 'cnf_submitted', 'cnf_exempt', 'cnf_missed']
      c.cnf_status = cnf_statuses.sample
      
      # CNF deadline should be after the project end date
      if c.cnf_status != 'not_claiming'
        c.cnf_deadline = end_date + rand(1..90).days
      end
    end
    
    created_claims << claim
    puts "Created R&D Claim: #{claim_title} for #{company.name}"
  end
  
  puts "Created #{created_claims.length} R&D claims"
  puts "Total R&D claims: #{RndClaim.count}"
else
  puts 'No user with id=1 found. Skipping additional demo data.'
end
