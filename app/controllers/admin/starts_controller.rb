class Admin::StartsController < ApplicationController
  def create
    meeting = Competition.find(params[:meeting_id])
    class_id = params[:class_id]

    provider_id = meeting.provider_competition_id
    provider_name = meeting.provider
    api_key = ApiCredential.find_by(name: provider_name)&.api_key

    unless api_key
      return redirect_to admin_meeting_path(meeting), alert: "Clé API manquante pour le provider '#{provider_name}'."
    end

    url = "https://app.equipe.com/meetings/#{provider_id}/competitions/#{class_id}/starts.json"
    headers = { "x-api-key" => api_key }

    Rails.logger.info "📡 Appel URL Equipe : #{url}"
    Rails.logger.info "🧾 class_id = #{class_id}"
    Rails.logger.info "🔐 provider_id = #{provider_id}"

    response = URI.open(url, headers).read
    starts_data = JSON.parse(response)

    created_count = 0
    updated_count = 0

    starts_data.each do |entry|
      next if entry["paus"].present? || entry["st"].nil?

      Rails.logger.info "⏸️ Ignoré (pause): start #{entry["st"]} / horse #{entry["horse_name"]}" if entry["paus"].present?

      start = StartsCompetition.find_or_initialize_by(
        Equipe_show_ID: provider_id,
        Equipe_class_ID: class_id,
        StartNb: entry["st"]
      )

      is_new_record = start.new_record?

      start.assign_attributes(
        horse_nb: entry["horse_no"],
        Rider_name: entry["rider_name"],
        Horse_Name: entry["horse_name"],
        Country: entry["rider_country"],
        Equipe_id: entry["id"]
      )

      start.save!

      if is_new_record
        created_count += 1
      else
        updated_count += 1
      end
    end

    message = []
    message << "#{created_count} nouvel(le)s départ(s) importé(s)" if created_count > 0
    message << "#{updated_count} mise(s) à jour" if updated_count > 0
    message = message.empty? ? "Aucune donnée à importer" : message.join(" – ")

    redirect_to videos_admin_meeting_path(meeting), notice: "📥 Épreuve #{class_id} : #{message}"
  rescue OpenURI::HTTPError => e
    redirect_to videos_admin_meeting_path(meeting), alert: "Erreur HTTP : #{e.message}"
  rescue => e
    redirect_to videos_admin_meeting_path(meeting), alert: "Erreur d'import : #{e.message}"
  end

  def exists
    provider_id = params[:provider_id]
    class_id = params[:class_id]

    exists = StartsCompetition.exists?(
      Equipe_show_ID: provider_id,
      Equipe_class_ID: class_id
    )

    render json: { exists: exists }
  end
end
