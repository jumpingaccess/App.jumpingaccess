class Api::TimekeepingController < ApplicationController
  before_action :authenticate_api_key
  skip_before_action :verify_authenticity_token

  def competitions
    # Stocker le timestamp de l'appel
    Rails.cache.write('nodejs_last_sync', Time.current, expires_in: 1.hour)

    competitions = Competition.where(provider: 'equipe', enable_queue: true)
                              .includes(:show_competitions)

    Rails.logger.info "API appelée par Node.js à #{Time.current}"
    # Retourner SEULEMENT les compétitions avec enable_queue = 1
    competitions = Competition.where(provider: 'equipe', enable_queue: true)
                              .includes(:show_competitions)

    Rails.logger.info "Found #{competitions.count} competitions with RabbitMQ enabled"

    response_data = {
      competitions: competitions.map do |comp|
        {
          provider_competition_id: comp.provider_competition_id,
          name: comp.name,
          classes: comp.show_competitions.map do |show_comp|
            {
              class_id: show_comp.class_ID,
              class_name: show_comp.class_name,
              start_time: show_comp.start_time,
              arena: show_comp.arena
            }
          end
        }
      end
    }

    Rails.logger.info "Returning #{competitions.count} competitions with RabbitMQ enabled"
    render json: response_data
  end

  def streams
    # Retourner la configuration des streams
    # Si vous avez un modèle Stream ou similaire, adaptez ici
    streams = [] # Remplacez par votre logique de streams

    render json: { streams: streams }
  end

  def incident_webhook
    # Traiter les incidents envoyés par Node.js
    incident_params = params.require(:incident).permit(
      :equipe_show_id, :equipe_class_id, :hnr, :startnb,
      :ridername, :horsename, :phase_course, :round_course,
      :type, :timestamp
    )

    Rails.logger.info "Incident reçu de Node.js: #{incident_params[:type]} pour #{incident_params[:ridername]} dans l'épreuve #{incident_params[:equipe_class_id]}"

    # Si vous avez un modèle Incident, créez-le ici
    # Incident.create!(incident_params)

    render json: { status: 'success', message: 'Incident enregistré' }
  rescue => e
    Rails.logger.error "Erreur incident webhook: #{e.message}"
    render json: { status: 'error', message: e.message }, status: 422
  end

  private

  private

  def authenticate_api_key
    api_key = request.headers['X-API-Key']
    expected_key = ENV['NODEJS_API_KEY'] || 'your-secret-key'

    # Logs temporaires pour debug
    Rails.logger.debug "Received API key: #{api_key}"
    Rails.logger.debug "Expected API key: #{expected_key}"
    Rails.logger.debug "Keys match: #{api_key == expected_key}"

    unless api_key == expected_key
      Rails.logger.error "API authentication failed - keys don't match"
      render json: { error: 'Unauthorized - Invalid API Key' }, status: 401
    end
  end
end