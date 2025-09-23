namespace :cnf_emails do
  desc "Create CNF emails for all existing R&D claims"
  task create_for_existing_claims: :environment do
    puts "Creating CNF emails for existing R&D claims..."
    
    RndClaim.includes(:company).find_each do |claim|
      puts "Processing claim: #{claim.title} (#{claim.company&.name})"
      
      # Create emails for all slots
      %w[1 2 3 4 5 6 FS].each do |slot|
        begin
          CnfEmail.create_for_claim(claim, slot)
          puts "  ✓ Created email for slot #{slot}"
        rescue => e
          puts "  ✗ Failed to create email for slot #{slot}: #{e.message}"
        end
      end
    end
    
    puts "CNF email creation completed!"
    puts "Total CNF emails created: #{CnfEmail.count}"
  end
  
  desc "Update existing CNF emails with new template content"
  task update_templates: :environment do
    puts "Updating CNF email templates..."
    
    CnfEmail.find_each do |email|
      email.update!(
        subject: CnfEmail.generate_subject(email.rnd_claim, email.template_type),
        body: CnfEmail.generate_body(email.rnd_claim, email.template_type)
      )
      puts "Updated email #{email.id} (#{email.email_slot})"
    end
    
    puts "Template update completed!"
  end

  desc "Update existing CNF emails to new status system and add demo data"
  task update_statuses_and_demo: :environment do
    puts "Updating CNF email statuses and adding demo data..."
    
    # Update all existing emails to 'to_be_sent' status
    CnfEmail.update_all(status: 'to_be_sent')
    puts "Updated all existing emails to 'to_be_sent' status"
    
    # Get some claims to add demo statuses
    claims = RndClaim.includes(:cnf_emails).limit(20)
    
    claims.each_with_index do |claim, claim_index|
      emails = claim.cnf_emails.order(:email_slot)
      
      emails.each_with_index do |email, email_index|
        # Create a pattern of different statuses
        case (claim_index + email_index) % 4
        when 0
          email.update!(status: 'sent', sent_at: 1.week.ago)
        when 1
          email.update!(status: 'to_be_sent')
        when 2
          email.update!(status: 'skipped')
        when 3
          email.update!(status: 'to_be_skipped')
        end
        
        puts "Updated #{claim.title} - Email #{email.email_slot}: #{email.status}"
      end
    end
    
    puts "Demo status update completed!"
    puts "Status distribution:"
    puts "  SENT: #{CnfEmail.sent.count}"
    puts "  TO BE SENT: #{CnfEmail.to_be_sent.count}"
    puts "  SKIPPED: #{CnfEmail.skipped.count}"
    puts "  TO BE SKIPPED: #{CnfEmail.to_be_skipped.count}"
  end
end
