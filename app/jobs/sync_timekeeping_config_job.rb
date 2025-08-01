# ========================================
# JOB POUR SYNCHRONISATION
# ========================================

# app/jobs/sync_timekeeping_config_job.rb
class SyncTimekeepingConfigJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Synchronizing timekeeping config with Node.js"
    TimekeepingIntegrationService.sync_streams_config
  end
end