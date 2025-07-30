require 'ostruct'

class Admin::StreamsController < ApplicationController
  before_action :set_castr_api_key, only: [:proxy_castr]
  skip_before_action :verify_authenticity_token, only: [:proxy_castr]

  def get_streams
    result = CastrApiService.fetch_streams
    log_action('Récupération des streams CastrIO') if result[:success]

    if result[:success]
      render json: { success: true, data: result[:data] }
    else
      render json: { success: false, message: result[:message] }, status: :bad_request
    end
  end

  def get_stream_endpoints
    stream_id = params[:stream_id] || params[:id]
    response = CastrApiService.fetch_streams

    if response[:success] && response[:data]["docs"].is_a?(Array)
      stream = response[:data]["docs"].find { |s| s["_id"] == stream_id }

      if stream
        platforms = stream["platforms"] || []
        render json: { success: true, data: platforms }
      else
        render json: { success: false, message: "Stream introuvable" }, status: :not_found
      end
    else
      render json: { success: false, message: "Erreur récupération flux" }, status: :bad_request
    end
  end

  def set_stream_endpoints
    result = CastrApiService.fetch_streams
    log_action('Configuration des streams pour le concours') if result[:success]
    render json: result
  end

  def endpoints
    stream_id = params[:id]
    result = CastrApiService.fetch_endpoints(stream_id)

    if result[:success]
      render json: { success: true, data: result[:data] }
    else
      render json: { success: false, message: result[:message] }, status: :bad_request
    end
  end

  def active
    @streams = CastrStream
      .where.not(Start_ingest: nil)
      .where(Stop_ingest: nil)
      .to_a

    @streams = @streams.map do |s|
      sc = ShowCompetition.find_by(show_ID: s.Equipe_show_ID, class_ID: s.Equipe_class_ID)
      competition = Competition.find_by(id: s.Equipe_show_ID)

      s.define_singleton_method(:arena) { sc&.arena }
      s.define_singleton_method(:class_name) { sc&.class_name }
      s.define_singleton_method(:competition_name) { competition&.name }

      s
    end

    render partial: "admin/streams/active", locals: { streams: @streams }
  end

  def proxy_castr
    begin
      data = JSON.parse(request.body.read).with_indifferent_access
    rescue JSON::ParserError => e
      return render json: { error: "Données JSON invalides" }, status: :unprocessable_entity
    end

    stream_id   = data[:stream_id]
    platform_id = data[:platform_id]
    action_type = data[:action_type]
    class_id    = data[:class_id]
    show_id     = data[:show_id]

    if [stream_id, platform_id, action_type, class_id, show_id].any?(&:blank?)
      return render json: { error: "Paramètres manquants" }, status: :unprocessable_entity
    end

    show_comp = ShowCompetition.find_by(class_id: class_id)
    return render json: { error: "Épreuve introuvable pour class_id #{class_id}" }, status: :unprocessable_entity unless show_comp

    competition_id = show_comp.class_ID
    competition = Competition.find_by(id: show_id)
    provider_show_id = competition&.provider_competition_id || show_id

    LoggerService.log_action(current_admin&.id || "-", 'Videos', "Stream #{action_type} → StreamID=#{stream_id}, PlatformID=#{platform_id}, ShowID=#{provider_show_id}, ClassID=#{competition_id}")

    return render json: { error: "provider_competition_id introuvable pour show_id #{show_id}" }, status: :unprocessable_entity unless provider_show_id

    # Appel Castr API v2
    url = URI("https://api.castr.com/v2/live_streams/#{stream_id}/platforms/#{platform_id}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Patch.new(url)
    request["accept"] = 'application/json'
    request["content-type"] = 'application/json'
    request["authorization"] = "Basic #{@castr_api_key}"
    request.body = { enabled: action_type == "start" }.to_json

    response = http.request(request)

    if response.code.to_i.between?(200, 299)
      update_stream_record(action_type, provider_show_id, competition_id, stream_id, platform_id)
      render json: { success: true }
    else
      render json: { success: false, status: response.code, message: response.body }, status: :bad_gateway
    end
  end
    def stats
      client = Antmedia::Client.new
      response = client.list_streams

      if response.success?
        render json: JSON.parse(response.body).map { |s|
          {
            id: s["streamId"],
            bitrate: s["bitrate"] || 0,
            status: s['status']
          }
        }
      else
        render json: [], status: :bad_gateway
      end
    end
  private

  def set_castr_api_key
    @castr_api_key = "cWM2dUwzWFl1dlIxOng5QTdobmJMRW9OcWxXVlFnd2FtNHdRSlIya3JjaU83UXBXeQ=="
  end

  def update_stream_record(action_type, show_id, class_id, stream_id, platform_id)
    brussels_time = Time.find_zone("Europe/Brussels").now
    timezone_name = "Europe/Brussels"

    if action_type == "start"
      CastrStream.where(Equipe_show_ID: show_id, Equipe_class_ID: class_id).delete_all

      CastrStream.create!(
        Equipe_show_ID: show_id,
        Equipe_class_ID: class_id,
        stream_id: stream_id,
        platform_id: platform_id,
        TimeZone: timezone_name,
        Start_ingest: brussels_time.strftime("%H:%M:%S"),
        created_at: Time.now,
        updated_at: Time.now
      )
    elsif action_type == "stop"
      record = CastrStream.find_by(Equipe_show_ID: show_id, Equipe_class_ID: class_id)
      if record
        record.update!(
          Stop_ingest: brussels_time.strftime("%H:%M:%S"),
          updated_at: Time.now
        )
      end
    end
  end

  def log_action(message)
    LoggerService.log_action(current_admin&.id || "-", 'Videos', message)
  end

  def current_admin
    admin_session = session[:admin]
    return nil unless admin_session.is_a?(Hash)

    OpenStruct.new(id: admin_session["id"])
  end
end
