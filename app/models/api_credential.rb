class ApiCredential < ApplicationRecord
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :api_key, presence: true

  # Normaliser le nom en minuscules avant sauvegarde
  before_save :normalize_name

  def self.for_provider(name)
    find_by('LOWER(name) = ?', name.downcase)
  end

  # Méthode helper pour récupérer directement la clé
  def self.get_key(provider_name)
    for_provider(provider_name)&.api_key
  end

  private

  def normalize_name
    self.name = name.downcase if name.present?
  end
end