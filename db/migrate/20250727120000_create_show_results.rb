class CreateShowResults < ActiveRecord::Migration[8.0]
  def change
    create_table :show_results do |t|
      t.text :Equipe_show_ID, null: false
      t.text :Equipe_class_ID, null: false
      t.integer :Ranking, null: false
      t.integer :StartNB
      t.integer :horse_nb, null: false
      t.text :Ridername, null: false
      t.text :Horsename, null: false
      t.text :Country, null: false
      t.text :results_preview, null: false
      t.text :prize, null: false

      t.timestamps
    end
  end
end
