class EquipeImportService
  def self.import_startlist(competition_id)
    competition = ShowCompetition.find(competition_id)
    json_url = "https://app.equipe.com/competitions/#{competition.provider_id}/startlist.json"
    
    response = HTTParty.get(json_url, headers: {
      "x-api-key" => ApiCredential.for_provider('equipe')&.key
    })

    if response.success?
      data = JSON.parse(response.body)
      # ici: parser et importer les cavaliers/chevaux
      return data # ou retourne le nombre importé
    else
      Rails.logger.error("Erreur Equipe: #{response.body}")
      []
    end
  end
end
