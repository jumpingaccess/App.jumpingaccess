class ShowCompetition < ApplicationRecord
   belongs_to :competition, optional: true  # ← Ajoutez optional: true
   # validates :competition, presence: true  # ← Commentez cette ligne
end