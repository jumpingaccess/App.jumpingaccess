class AddProviderToCompetitions < ActiveRecord::Migration[8.0]
  def change
    add_column :competitions, :provider, :string
  end
end
