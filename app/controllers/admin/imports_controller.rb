class Admin::ImportsController < ApplicationController
  layout "dashboard"
  before_action :require_login
  #before_action :require_admin

  def from_equipe
    @current_user_equipe_id = current_user.equipe_organizer_id
    @equipe_organizers = User.where.not(equipe_organizer_id: nil)

    # Vérifier que l'utilisateur a un ID Equipe
    unless current_user.is_equipe_organizer?
      flash[:alert] = "Vous devez avoir un ID organisateur Equipe pour utiliser cette fonctionnalité."
      redirect_to root_path
      return
    end

    # Vérifier que l'API key Equipe est configurée
    unless equipe_api_key.present?
      flash[:alert] = "Clé API Equipe non configurée. Contactez l'administrateur."
      redirect_to root_path
      return
    end

    # Charger les organisateurs depuis Equipe
    @organizers = fetch_organizers_from_equipe(current_user.equipe_organizer_id)
  end

  # Nouvelle route AJAX pour charger les concours
  def meetings
    organizer_id = params[:organizer_id]

    respond_to do |format|
      format.json do
        begin
          meetings = fetch_meetings_from_equipe(organizer_id)
          # Filtrer les concours non archivés
          active_meetings = meetings.select { |m| !m['archived'] }
          render json: active_meetings
        rescue => e
          Rails.logger.error "Erreur meetings: #{e.message}"
          render json: { error: e.message }, status: :unprocessable_entity
        end
      end
    end
  end

  def process_equipe_import
    begin
      organizer_id = params[:organizer_id]
      meeting_id = params[:meeting_id]

      if organizer_id.blank? || meeting_id.blank?
        raise "Organisateur et concours requis"
      end

      # Récupérer les détails du concours depuis Equipe
      meeting_data = fetch_specific_meeting_from_equipe(organizer_id, meeting_id)

      # Créer ou mettre à jour le concours dans la table competitions
      competition = create_or_update_competition(meeting_data)

      flash[:notice] = "Concours '#{competition.name}' importé avec succès !"
      redirect_to admin_import_equipe_path

    rescue => e
      Rails.logger.error "Erreur import Equipe: #{e.message}"
      flash.now[:alert] = "Erreur lors de l'import : #{e.message}"
      @current_user_equipe_id = current_user.equipe_organizer_id
      @equipe_organizers = User.where.not(equipe_organizer_id: nil)
      @organizers = fetch_organizers_from_equipe(current_user.equipe_organizer_id) rescue []
      redirect_to admin_import_equipe_path
    end
  end

  def hippodata
    # Afficher page ou lancer import JSON depuis Hippodata
  end

  def destroy
    type = params[:type] # "classes" ou "horses"
    id = params[:id].to_i

    case type
    when 'classes'
      concours = Competition.find_by(id: id)
      if concours
        ShowCompetition.where(show_ID: concours.provider_competition_id).delete_all
        flash[:notice] = "Toutes les épreuves importées ont été supprimées."
      else
        flash[:alert] = "Concours introuvable pour suppression des épreuves."
      end
    when 'horses'
      concours = Competition.find_by(id: id)
      if concours
        ShowHorse.where(Equipe_Show_ID: concours.provider_competition_id).delete_all
        flash[:notice] = "Tous les chevaux importés ont été supprimés."
      else
        flash[:alert] = "Concours introuvable pour suppression des chevaux."
      end
    else
      flash[:alert] = "Type d'importation invalide."
    end

    redirect_to admin_meeting_path(id)
  end

  private

  def equipe_api_key
    @equipe_api_key ||= ApiCredential.for_provider('equipe')&.api_key
  end

  def fetch_organizers_from_equipe(equipe_user_id)
    require 'net/http'
    require 'json'

    uri = URI("https://app.equipe.com/users/#{equipe_user_id}/organizers.json")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request['x-api-key'] = equipe_api_key
    request['Accept'] = 'application/json'

    response = http.request(request)

    if response.code == '200'
      JSON.parse(response.body)
    else
      Rails.logger.error "Erreur API Equipe organizers: #{response.code} - #{response.body}"
      []
    end
  rescue => e
    Rails.logger.error "Erreur fetch organizers: #{e.message}"
    []
  end

  def fetch_meetings_from_equipe(organizer_id)
    require 'net/http'
    require 'json'

    uri = URI("https://app.equipe.com/organizers/#{organizer_id}/meetings.json")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request['x-api-key'] = equipe_api_key
    request['Accept'] = 'application/json'

    response = http.request(request)

    if response.code == '200'
      JSON.parse(response.body)
    else
      raise "Erreur API Equipe meetings: #{response.code} - #{response.body}"
    end
  rescue => e
    Rails.logger.error "Erreur fetch meetings: #{e.message}"
    raise e
  end

  def fetch_specific_meeting_from_equipe(organizer_id, meeting_id)
    meetings = fetch_meetings_from_equipe(organizer_id)
    meeting = meetings.find { |m| m['id'].to_s == meeting_id.to_s }

    if meeting.nil?
      raise "Concours non trouvé"
    end

    meeting
  end

  def create_or_update_competition(meeting_data)
    Rails.logger.debug "=== CRÉATION COMPETITION ==="
    Rails.logger.debug "Meeting data: #{meeting_data.inspect}"

    competition = Competition.find_or_initialize_by(
      provider_competition_id: meeting_data['id'].to_s  # Convertir en string
    )

    Rails.logger.debug "Competition found/initialized: #{competition.inspect}"
    Rails.logger.debug "Is new record: #{competition.new_record?}"

    competition.assign_attributes(
      name: meeting_data['name'],
      start_date: Date.parse(meeting_data['starts_on']),     # starts_on → start_date
      end_date: Date.parse(meeting_data['ends_on']),         # ends_on → end_date
      source: 'equipe',                                      # archived/playground → source
      external_id: meeting_data['organizer_id'].to_s,       # organizer_id → external_id
      provider: 'equipe'
    )

    Rails.logger.debug "Competition after assign_attributes: #{competition.inspect}"
    Rails.logger.debug "Competition valid?: #{competition.valid?}"
    Rails.logger.debug "Competition errors: #{competition.errors.full_messages}" unless competition.valid?

    if competition.save!
      Rails.logger.debug "Competition saved successfully with ID: #{competition.id}"
    else
      Rails.logger.error "Failed to save competition: #{competition.errors.full_messages}"
    end

    competition
  rescue => e
    Rails.logger.error "Error in create_or_update_competition: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5)}"
    raise e
  end
end