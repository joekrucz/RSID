# Automatically run db:seed once on first boot in production (or when enabled explicitly)
# To force-run again, delete tmp/seeds_ran marker file or set AUTO_RUN_SEEDS_FORCE=true.

if (Rails.env.production? || ENV["AUTO_RUN_SEEDS"] == "true") && !ENV["AUTO_RUN_SEEDS_DISABLED"]
  begin
    marker_path = Rails.root.join("tmp", "seeds_ran")
    force = ENV["AUTO_RUN_SEEDS_FORCE"] == "true"

    unless File.exist?(marker_path) && !force
      Rails.logger.info("[Seeds] Running db:seed on boot#{force ? ' (forced)' : ''}...")
      require "rake"
      Rails.application.load_tasks
      Rake::Task["db:seed"].reenable
      Rake::Task["db:seed"].invoke
      FileUtils.mkdir_p(marker_path.dirname)
      FileUtils.touch(marker_path)
      Rails.logger.info("[Seeds] Completed and marker written to #{marker_path}")
    else
      Rails.logger.info("[Seeds] Skip: marker exists at #{marker_path}")
    end
  rescue => e
    Rails.logger.error("[Seeds] Error: #{e.class} - #{e.message}")
  end
end


