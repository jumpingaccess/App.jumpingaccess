class AddCountryToCompetitions < ActiveRecord::Migration[8.0]
  def change
    add_column :competitions, :country, :string
  end
end
