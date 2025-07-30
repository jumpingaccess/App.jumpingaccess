# app/models/user.rb
class User < ApplicationRecord
    has_secure_password
    ROLES = %w[admin utilisateur manager]
    validates :role, presence: true, inclusion: { in: ROLES }
  
    def generate_reset_token!
      update!(
        reset_password_token: SecureRandom.urlsafe_base64,
        reset_password_sent_at: Time.current
      )
    end
  
    def reset_token_valid?
      reset_password_sent_at && reset_password_sent_at > 2.hours.ago
    end
  
    def clear_reset_token!
      update!(
        reset_password_token: nil,
        reset_password_sent_at: nil
      )
    end
  end
  