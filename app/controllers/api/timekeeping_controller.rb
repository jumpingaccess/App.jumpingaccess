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