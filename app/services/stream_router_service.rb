class StreamRouterService
  def self.start(stream_url, competition_id)
    # ici on configure Castr pour router vers la bonne destination
    Rails.logger.info("Démarrage stream pour épreuve #{competition_id} vers #{stream_url}")
    # Optionnel: enregistrement DB/log/streaming state
  end

  def self.stop(stream_url)
    Rails.logger.info("Arrêt du stream vers #{stream_url}")
    # Appel API Castr ou simplement log, selon ton besoin
  end
end
