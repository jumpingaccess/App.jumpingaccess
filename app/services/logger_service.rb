class LoggerService
  def self.log_action(admin_id, category, message)
    Rails.logger.debug("[ADMIN ##{admin_id}] #{category} → #{message}")
    # Ou sauvegarder dans une table dédiée si tu veux une trace DB
  end
end