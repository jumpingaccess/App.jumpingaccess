# ========================================
# CÔTÉ RAILS : Service d'intégration
# ========================================

# app/services/timekeeping_integration_service.rb
class TimekeepingIntegrationService
  def self.enable_competition_queue(competition_id)
    competition = Competition.find(competition_id)

    # 1. Activer la queue dans Rails
    competition.update!(rabbitmq_enabled: true, enable_queue: true)

    # 2. Notifier Node.js via RabbitMQ
    notify_nodejs({
                    action: 'enable_competition',
                    competition_id: competition.id,
                    provider_competition_id: competition.provider_competition_id,
                    classes: competition.show_competitions.pluck(:class_ID)
                  })

    Rails.logger.info "Queue enabled for competition #{competition_id}"
  end

  def self.disable_competition_queue(competition_id)
    competition = Competition.find(competition_id)
    competition.update!(rabbitmq_enabled: false, enable_queue: false)

    notify_nodejs({
                    action: 'disable_competition',
                    competition_id: competition.id,
                    provider_competition_id: competition.provider_competition_id
                  })
  end

  def self.sync_streams_config
    # Synchroniser la config des streams avec Node.js
    streams_config = AntmediaStream.includes(:meeting).map do |stream|
      {
        piste_name: stream.piste_name,
        stream_key: stream.stream_key,
        meeting_id: stream.meeting_id,
        provider_competition_id: stream.meeting.provider_competition_id
      }
    end

    notify_nodejs({
                    action: 'sync_streams',
                    streams: streams_config
                  })
  end

  private

  def self.notify_nodejs(message)
    begin
      connection = Bunny.new(ENV.fetch('RABBITMQ_URL', 'amqp://localhost:5672'))
      connection.start
      channel = connection.create_channel

      queue = channel.queue('rails_to_nodejs_commands', durable: true)
      queue.publish(message.to_json, persistent: true)

      channel.close
      connection.close

      Rails.logger.info "Message sent to Node.js: #{message[:action]}"
    rescue => e
      Rails.logger.error "Failed to notify Node.js: #{e.message}"
    end
  end
end

# ========================================
# CONTRÔLEUR RAILS AMÉLIORÉ
# ========================================

# app/controllers/admin/competitions_controller.rb
class Admin::CompetitionsController < ApplicationController
  # ... existing code ...

  def enable_timekeeping
    @competition = Competition.find(params[:id])

    begin
      TimekeepingIntegrationService.enable_competition_queue(@competition.id)
      redirect_to admin_meeting_path(@competition),
                  notice: "Chronométrage activé pour ce concours"
    rescue => e
      Rails.logger.error "Enable timekeeping error: #{e.message}"
      redirect_to admin_meeting_path(@competition),
                  alert: "Erreur lors de l'activation du chronométrage"
    end
  end

  def disable_timekeeping
    @competition = Competition.find(params[:id])

    begin
      TimekeepingIntegrationService.disable_competition_queue(@competition.id)
      redirect_to admin_meeting_path(@competition),
                  notice: "Chronométrage désactivé"
    rescue => e
      Rails.logger.error "Disable timekeeping error: #{e.message}"
      redirect_to admin_meeting_path(@competition),
                  alert: "Erreur lors de la désactivation"
    end
  end
end

# ========================================
# API POUR NODE.JS
# ========================================

# app/controllers/api/timekeeping_controller.rb
class Api::TimekeepingController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_api_key

  def competitions
    # Node.js peut récupérer les compétitions actives
    competitions = Competition.where(rabbitmq_enabled: true, enable_queue: true)
                              .includes(:show_competitions)

    render json: {
      competitions: competitions.map do |comp|
        {
          id: comp.id,
          provider_competition_id: comp.provider_competition_id,
          name: comp.name,
          classes: comp.show_competitions.map do |sc|
            {
              class_id: sc.class_ID,
              class_name: sc.class_name,
              arena: sc.arena
            }
          end
        }
      end
    }
  end

  def streams
    # Node.js peut récupérer la config des streams
    streams = AntmediaStream.includes(:meeting)
                            .where(meetings: { rabbitmq_enabled: true })

    render json: {
      streams: streams.map do |stream|
        {
          piste_name: stream.piste_name,
          stream_key: stream.stream_key,
          meeting_id: stream.meeting_id,
          provider_competition_id: stream.meeting.provider_competition_id
        }
      end
    }
  end

  def incident_webhook
    # Recevoir les incidents depuis Node.js
    incident_data = params.require(:incident)

    EquipeIncidentWebhook.create!(
      equipe_show_id: incident_data[:equipe_show_id],
      equipe_class_id: incident_data[:equipe_class_id],
      hnr: incident_data[:hnr],
      startnb: incident_data[:startnb],
      ridername: incident_data[:ridername],
      horsename: incident_data[:horsename],
      phase_course: incident_data[:phase_course],
      round_course: incident_data[:round_course],
      type: incident_data[:type],
      timestamp: incident_data[:timestamp]
    )

    render json: { status: 'success' }
  rescue => e
    Rails.logger.error "Incident webhook error: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def verify_api_key
    api_key = request.headers['X-API-Key']
    unless api_key == ENV['NODEJS_API_KEY']
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end

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

# ========================================
# CALLBACK POUR AUTO-SYNC
# ========================================

# app/models/antmedia_stream.rb
class AntmediaStream < ApplicationRecord
  # ... existing code ...

  after_save :sync_with_nodejs
  after_destroy :sync_with_nodejs

  private

  def sync_with_nodejs
    SyncTimekeepingConfigJob.perform_later if meeting&.rabbitmq_enabled?
  end
end