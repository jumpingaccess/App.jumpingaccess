class Competition < ApplicationRecord
    has_one_attached :logo # si tu utilises ActiveStorage

    has_many :show_competitions,
             foreign_key: "show_ID",
             primary_key: "provider_competition_id",
             class_name: "ShowCompetition"
    def webp_logo
        logo.variant(format: :webp).processed
    end
end
