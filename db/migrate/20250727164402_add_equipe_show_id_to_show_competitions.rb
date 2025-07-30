class AddEquipeShowIdToShowCompetitions < ActiveRecord::Migration[8.0]
  def change
      add_column :show_competitions, :equipe_show_id, :bigint
    add_index :show_competitions, :equipe_show_id
  end
end
