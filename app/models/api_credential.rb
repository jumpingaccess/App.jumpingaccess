class ApiCredential < ApplicationRecord
  def self.for_provider(name)
    find_by('LOWER(name) = ?', name.downcase)
  end
end
