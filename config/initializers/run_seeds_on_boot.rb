# Automatically run db:seed once on first boot in production (or when enabled explicitly)
# To force-run again, delete tmp/seeds_ran marker file or set AUTO_RUN_SEEDS_FORCE=true.

// Only run when explicitly enabled via env. Avoid running during image build/asset compile.
if ENV["AUTO_RUN_SEEDS"] == "true" && !ENV["AUTO_RUN_SEEDS_DISABLED"]
  begin
    marker_path = Rails.root.join("tmp", "seeds_ran")
    force = ENV["AUTO_RUN_SEEDS_FORCE"] == "true"

    # Skip if migrations are pending
    needs_migration = false
    begin
      ActiveRecord::Base.connection
      ctx = ActiveRecord::Base.connection.migration_context
      needs_migration = ctx.respond_to?(:needs_migration?) ? ctx.needs_migration? : (ctx.open.pending_migrations.any?)
    rescue => e
      Rails.logger.warn("[Seeds] Could not check migration status: #{e.class} - #{e.message}")
    end

    unless (File.exist?(marker_path) && !force) || needs_migration
      Rails.logger.info("[Seeds] Running db:seed on boot#{force ? ' (forced)' : ''}...")
      require "rake"
      Rails.application.load_tasks
      Rake::Task["db:seed"].reenable
      Rake::Task["db:seed"].invoke
      FileUtils.mkdir_p(marker_path.dirname)
      FileUtils.touch(marker_path)
      Rails.logger.info("[Seeds] Completed and marker written to #{marker_path}")
    else
      if needs_migration
        Rails.logger.info("[Seeds] Skip: pending migrations detected; will run on next boot after migrations")
      else
        Rails.logger.info("[Seeds] Skip: marker exists at #{marker_path}")
      end
    end
  rescue => e
    Rails.logger.error("[Seeds] Error: #{e.class} - #{e.message}")
  end
end


