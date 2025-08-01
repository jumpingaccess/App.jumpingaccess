# app/models/user.rb
class User < ApplicationRecord
    has_secure_password
    ROLES = %w[admin utilisateur manager]
    validates :role, presence: true, inclusion: { in: ROLES }
    # Validation pour l'ID organisateur Equipe
    validates :equipe_organizer_id, uniqueness: true, allow_blank: true
    def generate_reset_token!
      update!(
        reset_password_token: SecureRandom.urlsafe_base64,
        reset_password_sent_at: Time.current
      )
    end
  
    def reset_token_valid?
      reset_password_sent_at && reset_password_sent_at > 2.hours.ago
    end

    def is_equipe_organizer?
      equipe_organizer_id.present?
    end

    # Méthode pour trouver un utilisateur par son ID Equipe
    scope :by_equipe_organizer_id, ->(id) { where(equipe_organizer_id: id) }
    def clear_reset_token!
      update!(
        reset_password_token: nil,
        reset_password_sent_at: nil
      )
    end
  end
  