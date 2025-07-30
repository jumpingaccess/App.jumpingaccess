
class CreateStartsCompetitions < ActiveRecord::Migration[8.0]
  def change
    create_table :starts_competitions do |t|
      t.text :Equipe_show_ID, null: false
      t.text :Equipe_class_ID, null: false
      t.text :StartNb, null: false
      t.text :horse_nb, null: false
      t.text :Rider_name, null: false
      t.text :Horse_Name, null: false
      t.text :Country, null: false
      t.integer :Equipe_id

      t.timestamps
    end
  end
end