# app/controllers/admin/results_controller.rb

class Admin::ResultsController < ApplicationController
  def create
    meeting = Competition.find(params[:meeting_id])
    class_id = params[:class_id]
    provider_id = meeting.provider_competition_id
    provider_name = meeting.provider
    api_key = ApiCredential.find_by(name: provider_name)&.api_key

    unless api_key
      return redirect_to videos_admin_meeting_path(meeting), alert: "Clé API manquante pour le provider '#{provider_name}'."
    end

    url = "https://app.equipe.com/meetings/#{provider_id}/competitions/#{class_id}/H/results.json"
    headers = { "x-api-key" => api_key }
      Rails.logger.info "📡 Appel URL Equipe : #{url}"
    Rails.logger.info "🧾 class_id = #{class_id}"
    Rails.logger.info "🔐 provider_id = #{provider_id}"
    response = URI.open(url, headers).read
    results_data = JSON.parse(response)

    updates = 0
    creations = 0

    results_data.each do |entry|
      next if entry["re"].nil? || entry["st"].nil?

      result = ShowResult.find_or_initialize_by(
        Equipe_show_ID: provider_id,
        Equipe_class_ID: class_id,
        StartNB: entry["st"]
      )

      result.assign_attributes(
        Ranking: entry["re"],
        horse_nb: entry["horse_no"],
        Ridername: entry["rider_name"],
        Horsename: entry["horse_name"],
        Country: entry["rider_country"],
        results_preview: entry["result_preview"],
        prize: entry["premie"].to_s
      )

      result.new_record? ? creations += 1 : updates += 1
      result.save!
    end

    message = creations.positive? ? "Résultats importés pour l'épreuve #{class_id}." : "Résultats mis à jour pour l'épreuve #{class_id}."
    redirect_to videos_admin_meeting_path(meeting), notice: message
  rescue OpenURI::HTTPError => e
    redirect_to videos_admin_meeting_path(meeting), alert: "Erreur HTTP : #{e.message}"
  rescue => e
    redirect_to videos_admin_meeting_path(meeting), alert: "Erreur d'import : #{e.message}"
  end

  def exists
    exists = ShowResult.exists?(
      Equipe_show_ID: params[:provider_id],
      Equipe_class_ID: params[:class_id]
    )

    render json: { exists: exists }
  end
end
