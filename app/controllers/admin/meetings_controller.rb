class Admin::MeetingsController < ApplicationController
  layout "dashboard"
  before_action :require_login
  before_action :set_meeting, only: [:show, :videos, :start_stream, :stop_stream, :import_startlist]
  def show
    @concours = Competition.find(params[:id])
    # tu peux charger ici toutes les données utiles (vidéos, streams, etc.)
  end

  def classimport
    competition = Competition.find(params[:id])
    provider = competition.provider # 'equipe' ou 'hippodata'
    provider_competition_id = competition.provider_competition_id

    credential = ApiCredential.find_by(name: provider)
    api_key = credential&.api_key

    if api_key.blank?
      redirect_back fallback_location: admin_dashboard_path, alert: "Clé API manquante pour le provider #{provider}"
      return
    end

    url = "https://app.equipe.com/meetings/#{provider_competition_id}/competitions.json"
    response = Faraday.get(url) do |req|
      req.headers['x-api-key'] = api_key
    end

    if response.success?
      competitions_data = JSON.parse(response.body)

      created_count = 0
      updated_count = 0

      competitions_data.each do |data|
        next unless data['z'] == 'H' && data['klass'] != 'Do not compete'

        show_competition = ShowCompetition.find_or_initialize_by(
          show_ID: provider_competition_id,
          class_ID: data[ 'kq']
        )

        was_new = show_competition.new_record?

        show_competition.assign_attributes(
          datum: data['datum'],
          class_num: data['clabb'],
          class_name: data['klass'],
          Headtitle: data['oeverskr1'],
          subtitle: data['oeverskr1'],
          start_time: data['klock'],
          arena: data['tavlingspl'],
          Currency: data['premie_curr'],
          FEI_ID_Class: data['feiid']
        )

        if show_competition.save
          was_new ? created_count += 1 : updated_count += 1
        end
      end

      total = created_count + updated_count
      
      redirect_to admin_meeting_path(competition.id), notice: "#{total} épreuves importées : #{created_count} créées, #{updated_count} mises à jour."
    else
      redirect_to admin_meeting_path(competition.id), alert: "Erreur d'import depuis Equipe : #{response.status}"
    end

  end

  def horseimport
    competition = Competition.find(params[:id])
    provider = competition.provider
    provider_competition_id = competition.provider_competition_id

    credential = ApiCredential.find_by(name: provider)
    api_key = credential&.api_key

    if api_key.blank?
      redirect_to admin_meeting_path(competition), alert: "Clé API manquante pour le provider #{provider}"
      return
    end

    url = "https://app.equipe.com/meetings/#{provider_competition_id}/horses.json"
    response = Faraday.get(url) { |req| req.headers['x-api-key'] = api_key }

    if response.success?
      horses_data = JSON.parse(response.body)

      created = 0
      updated = 0

      horses_data.each do |data|
        next if data['hnr'].blank? || data['name'].blank?

        horse = ShowHorse.find_or_initialize_by(
          Equipe_Show_ID: provider_competition_id,
          headnum: data['hnr']
        )

        was_new = horse.new_record?

        horse.assign_attributes(
          horsename:  data['name'],
          born_year:  data['born_year'],
          FEI_ID:     data['fei_id'],
          Breed:      data['breed'] || "",
          Breeder:    data['breeder'] || "",
          Sire:       data['sire'] || "",
          SireDam:    data['dam_sire'] || "",
          color:      data['color'] || "",
          owner:      data['owner'] || "",
          sex:        data['sex'] || ""
        )

        if horse.save
          was_new ? created += 1 : updated += 1
        end
      end

      redirect_to admin_meeting_path(competition), notice: "#{created + updated} chevaux importés : #{created} créés, #{updated} mis à jour."
    else
      redirect_to admin_meeting_path(competition), alert: "Erreur lors de l'import des chevaux : #{response.status}"
    end
  end




  def videos
    @meeting = Competition.find(params[:id]) # si Meeting = Competition
    @show_competitions = ShowCompetition.order(:datum)
    streams_response = CastrApiService.fetch_streams
    #@castr_streams = streams_response[:success] ? streams_response[:data] : []
    @castr_streams = CastrApiService.fetch_streams[:data] || { "docs" => [] }
    @pistes = ShowCompetition.where.not(arena: [nil, ""]).distinct.pluck(:arena).map { |a| { label: a } }
  end

  def start_stream
    StreamRouterService.start(params[:stream_url], params[:competition_id])
    redirect_to videos_admin_meeting_path(params[:id]), notice: "Stream lancé."
  end

  def stop_stream
    StreamRouterService.stop(params[:stream_url])
    redirect_to videos_admin_meeting_path(params[:id]), alert: "Stream arrêté."
  end

  def import_startlist
    count = EquipeImportService.import_startlist(params[:competition_id])
    redirect_to videos_admin_meeting_path(params[:id]), notice: "#{count} cavaliers importés."
  end

  def set_meeting
    @meeting = Competition.find(params[:id]) # ou Meeting.find(params[:id]) selon ton modèle
  end
end
