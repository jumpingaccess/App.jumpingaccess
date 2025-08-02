# app/services/equipe_import_service.rb
class EquipeImportService
  attr_reader :competition, :api_key

  def initialize(competition)
    @competition = competition
    @api_key = ApiCredential.for_provider('equipe')&.api_key
  end

  # ✅ Nouvelle méthode pour importer les classes/épreuves
  def import_classes
    return error_response("Clé API manquante") unless @api_key
    return error_response("Competition manquante") unless @competition

    begin
      response = fetch_competitions_data
      return error_response("Erreur API: #{response.code}") unless response.success?

      process_competitions_data(JSON.parse(response.body))
    rescue JSON::ParserError => e
      Rails.logger.error "JSON Parse Error: #{e.message}"
      error_response("Données JSON invalides")
    rescue => e
      Rails.logger.error "EquipeImportService#import_classes error: #{e.message}"
      error_response(e.message)
    end
  end

  # ✅ Nouvelle méthode pour importer les chevaux
  def import_horses
    return error_response("Clé API manquante") unless @api_key
    return error_response("Competition manquante") unless @competition

    begin
      response = fetch_horses_data
      return error_response("Erreur API: #{response.code}") unless response.success?

      process_horses_data(JSON.parse(response.body))
    rescue => e
      Rails.logger.error "EquipeImportService#import_horses error: #{e.message}"
      error_response(e.message)
    end
  end

  # ✅ Méthode existante améliorée
  def import_startlist(class_id)
    return error_response("Clé API manquante") unless @api_key
    return error_response("Class ID manquant") unless class_id

    begin
      response = fetch_startlist_data(class_id)
      return error_response("Erreur API: #{response.code}") unless response.success?

      process_startlist_data(JSON.parse(response.body), class_id)
    rescue => e
      Rails.logger.error "EquipeImportService#import_startlist error: #{e.message}"
      error_response(e.message)
    end
  end

  # ✅ Méthode statique pour compatibilité avec l'existant
  def self.import_startlist(competition_id)
    competition = ShowCompetition.find(competition_id)
    service = new(Competition.find_by(provider_competition_id: competition.show_ID))
    service.import_startlist(competition.class_ID)
  rescue => e
    Rails.logger.error "Static import_startlist error: #{e.message}"
    { success: false, error: e.message }
  end

  private

  # === Méthodes de récupération de données ===

  def fetch_competitions_data
    url = "https://app.equipe.com/meetings/#{@competition.provider_competition_id}/competitions.json"
    make_api_request(url)
  end

  def fetch_horses_data
    url = "https://app.equipe.com/meetings/#{@competition.provider_competition_id}/horses.json"
    make_api_request(url)
  end

  def fetch_startlist_data(class_id)
    url = "https://app.equipe.com/meetings/#{@competition.provider_competition_id}/competitions/#{class_id}/starts.json"
    make_api_request(url)
  end

  def make_api_request(url)
    HTTParty.get(url, {
      headers: {
        "x-api-key" => @api_key,
        "Content-Type" => "application/json"
      },
      timeout: 30
    })
  end

  # === Méthodes de traitement ===

  def process_competitions_data(data)
    created_count = 0
    updated_count = 0

    data.each do |competition_data|
      next unless valid_competition?(competition_data)

      show_competition = find_or_initialize_competition(competition_data)
      was_new = show_competition.new_record?

      if update_competition_attributes(show_competition, competition_data)
        was_new ? created_count += 1 : updated_count += 1
      end
    end

    success_response(created_count, updated_count, "épreuves")
  end

  def process_horses_data(data)
    created_count = 0
    updated_count = 0

    data.each do |horse_data|
      next if horse_data['hnr'].blank? || horse_data['name'].blank?

      horse = find_or_initialize_horse(horse_data)
      was_new = horse.new_record?

      if update_horse_attributes(horse, horse_data)
        was_new ? created_count += 1 : updated_count += 1
      end
    end

    success_response(created_count, updated_count, "chevaux")
  end

  def process_startlist_data(data, class_id)
    created_count = 0
    updated_count = 0

    data.each do |start_data|
      next if start_data['paus'].present? || start_data['st'].nil?

      start = find_or_initialize_start(start_data, class_id)
      was_new = start.new_record?

      if update_start_attributes(start, start_data)
        was_new ? created_count += 1 : updated_count += 1
      end
    end

    success_response(created_count, updated_count, "départs")
  end

  # === Méthodes de validation et recherche ===

  def valid_competition?(data)
    data['z'] == 'H' && data['klass'] != 'Do not compete'
  end

  def find_or_initialize_competition(data)
    ShowCompetition.find_or_initialize_by(
      show_ID: @competition.provider_competition_id,
      class_ID: data['kq']
    )
  end

  def find_or_initialize_horse(data)
    ShowHorse.find_or_initialize_by(
      Equipe_Show_ID: @competition.provider_competition_id,
      headnum: data['hnr']
    )
  end

  def find_or_initialize_start(data, class_id)
    StartsCompetition.find_or_initialize_by(
      Equipe_show_ID: @competition.provider_competition_id,
      Equipe_class_ID: class_id,
      StartNb: data['st']
    )
  end

  # === Méthodes de mise à jour ===

  def update_competition_attributes(show_competition, data)
    show_competition.assign_attributes(
      datum: parse_date(data['datum']),
      class_num: data['clabb'],
      class_name: sanitize_text(data['klass']),
      Headtitle: sanitize_text(data['oeverskr1']),
      subtitle: sanitize_text(data['oeverskr1']),
      start_time: data['klock'],
      arena: sanitize_text(data['tavlingspl']),
      Currency: data['premie_curr'],
      FEI_ID_Class: data['feiid']
    )

    show_competition.save
  end

  def update_horse_attributes(horse, data)
    horse.assign_attributes(
      horsename: sanitize_text(data['name']),
      born_year: data['born_year'],
      FEI_ID: data['fei_id'],
      Breed: sanitize_text(data['breed'] || ""),
      Breeder: sanitize_text(data['breeder'] || ""),
      Sire: sanitize_text(data['sire'] || ""),
      SireDam: sanitize_text(data['dam_sire'] || ""),
      color: sanitize_text(data['color'] || ""),
      owner: sanitize_text(data['owner'] || ""),
      sex: sanitize_text(data['sex'] || "")
    )

    horse.save
  end

  def update_start_attributes(start, data)
    start.assign_attributes(
      horse_nb: data['horse_no'],
      Rider_name: sanitize_text(data['rider_name']),
      Horse_Name: sanitize_text(data['horse_name']),
      Country: data['rider_country'],
      Equipe_id: data['id']
    )

    start.save
  end

  # === Méthodes utilitaires ===

  def parse_date(date_string)
    Date.parse(date_string) if date_string.present?
  rescue Date::Error
    Rails.logger.warn "Impossible de parser la date: #{date_string}"
    nil
  end

  def sanitize_text(text)
    text&.strip&.truncate(255)
  end

  def success_response(created, updated, type)
    {
      success: true,
      created: created,
      updated: updated,
      total: created + updated,
      message: "#{created + updated} #{type} importé(s) : #{created} créé(s), #{updated} mis à jour"
    }
  end

  def error_response(message)
    {
      success: false,
      error: message,
      created: 0,
      updated: 0,
      total: 0
    }
  end
end