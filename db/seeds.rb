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
