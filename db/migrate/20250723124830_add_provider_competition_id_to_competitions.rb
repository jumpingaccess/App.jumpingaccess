class AddProviderCompetitionIdToCompetitions < ActiveRecord::Migration[8.0]
  def change
    add_column :competitions, :provider_competition_id, :string
  end
end
