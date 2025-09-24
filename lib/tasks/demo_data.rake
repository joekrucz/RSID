namespace :demo do
  desc "Seed demo data for CNF emails and R&D claims"
  task seed: :environment do
    puts "Seeding demo data..."
    
    # Only run if we're in production or explicitly requested
    if Rails.env.production? || ENV['FORCE_DEMO_SEED'] == 'true'
      puts "Running in #{Rails.env} environment"
      
      # Create companies if they don't exist
      sample_companies = [
        { name: 'Acme Corp', website: 'https://acme.example', notes: 'Manufacturing' },
        { name: 'Globex', website: 'https://globex.example', notes: 'Technology' },
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

      # Create R&D claims with CNF emails
      Company.all.each_with_index do |company, index|
        # Ensure demo data only has period ends in 2024 or 2025 and covers every month
        months_2024_2025 = []
        (1..12).each { |m| months_2024_2025 << [2024, m] }
        (1..12).each { |m| months_2024_2025 << [2025, m] }
        months_2024_2025 = (months_2024_2025 * 6) # 6 cycles = 144 months, more than 125
        
        year, month = months_2024_2025[index % months_2024_2025.length]
        end_date = Date.new(year, month, -1) # last day of the month
        start_date = end_date - 364
        
        # Title based on period end date: abbreviated month + FY (e.g., "Mar FY23")
        claim_title = "#{end_date.strftime('%b')} FY#{end_date.strftime('%y')}"

        claim = RndClaim.find_or_initialize_by(company: company)
        claim.start_date = start_date
        claim.end_date = end_date
        claim.title = claim_title
        claim.stage = ['upcoming', 'readying_for_delivery', 'in_progress', 'finalised', 'filed_awaiting_hmrc', 'claim_processed', 'client_invoiced', 'paid'].sample
        claim.qualifying_activities = [
          "Software development and testing",
          "Prototype development and validation",
          "Technical research and analysis",
          "Process improvement and optimization",
          "Innovation and product development"
        ].sample(rand(2..4)).join(", ")
        claim.technical_challenges = [
          "Scalability and performance optimization",
          "Integration with existing systems",
          "Data security and compliance requirements",
          "User experience and interface design",
          "Algorithm development and optimization"
        ].sample(rand(2..3)).join(", ")
        
        # CNF status and deadline - ensure no future deadlines have "missed" status
        cnf_deadline = end_date + 6.months
        today = Date.current
        
        if cnf_deadline > today
          # Future deadline - can't be missed yet
          cnf_statuses = ['not_claiming', 'cnf_needed', 'cnf_exemption_possible', 'in_progress', 'cnf_submitted', 'cnf_exempt']
        else
          # Past or current deadline - can be any status
          cnf_statuses = ['not_claiming', 'cnf_needed', 'cnf_exemption_possible', 'in_progress', 'cnf_submitted', 'cnf_exempt', 'cnf_missed']
        end
        
        claim.cnf_status = cnf_statuses.sample
        
        # CNF deadline should be 6 months after the project end date
        if claim.cnf_status != 'not_claiming'
          claim.cnf_deadline = cnf_deadline
        else
          claim.cnf_deadline = nil
        end

        # Set cnf_submission_date only for 'cnf_submitted' claims and within 6 months of period end
        if claim.cnf_status == 'cnf_submitted' && claim.end_date
          max_submission_date = claim.end_date + 6.months - 1.day
          min_submission_date = claim.end_date + 1.day
          
          if min_submission_date <= max_submission_date
            claim.cnf_submission_date = rand(min_submission_date..max_submission_date)
          else
            claim.cnf_submission_date = min_submission_date
          end
        else
          claim.cnf_submission_date = nil
        end

        claim.save!
        
        # Create CNF emails for this claim
        next unless claim.end_date
        
        end_date = claim.end_date.is_a?(String) ? Date.parse(claim.end_date) : claim.end_date
        cnf_deadline = end_date + 6.months
        
        %w[1 2 3 4 5 6 FS].each do |slot|
          CnfEmail.find_or_create_by(rnd_claim: claim, email_slot: slot) do |email|
            template_type = case slot
                           when '1' then 'initial'
                           when '2', '3', '4', '5' then 'monthly'
                           when '6', 'FS' then 'urgent'
                           else 'initial'
                           end
            
            email_send_date = case slot
                             when '1' then (end_date + 1.month).beginning_of_month
                             when '2' then (end_date + 2.months).beginning_of_month
                             when '3' then (end_date + 3.months).beginning_of_month
                             when '4' then (end_date + 4.months).beginning_of_month
                             when '5' then (end_date + 5.months).beginning_of_month
                             when '6' then (end_date + 6.months).beginning_of_month
                             when 'FS' then cnf_deadline - 2.weeks
                             else (end_date + 1.month).beginning_of_month
                             end
            
            today = Date.current
            if email_send_date <= today
              email.status = 'sent'
              email.sent_at = email_send_date.beginning_of_day
            elsif email_send_date <= today + 1.week
              email.status = 'to_be_sent'
            else
              email.status = 'to_be_sent'
            end
            
            email.template_type = template_type
            email.recipient_email = CnfEmail.generate_recipient_email(claim)
            email.subject = CnfEmail.generate_subject(claim, template_type)
            email.body = CnfEmail.generate_body(claim, template_type)
          end
        end
      end
      
      puts "Demo data seeded successfully!"
      puts "Created #{Company.count} companies"
      puts "Created #{RndClaim.count} R&D claims"
      puts "Created #{CnfEmail.count} CNF emails"
    else
      puts "Skipping demo data seeding in #{Rails.env} environment"
      puts "To force seeding, run: FORCE_DEMO_SEED=true bin/rails demo:seed"
    end
  end
end
