# app/models/starts_competition.rb
class StartsCompetition < ApplicationRecord
  validates :Equipe_show_ID, :Equipe_class_ID, :StartNb, :horse_nb, presence: true
end