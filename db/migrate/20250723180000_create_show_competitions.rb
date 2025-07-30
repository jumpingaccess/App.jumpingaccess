# db/migrate/20250723180000_create_show_competitions.rb
class CreateShowCompetitions < ActiveRecord::Migration[7.1]
  def change
    create_table :show_competitions do |t|
      t.text :show_ID, null: false
      t.text :class_ID, null: false
      t.date :datum, null: false
      t.text :class_num, null: false
      t.text :class_name, null: false
      t.text :Headtitle, null: false
      t.text :subtitle, null: false
      t.text :start_time
      t.text :arena, null: false
      t.text :Currency, null: false
      t.text :FEI_ID_Class

      t.timestamps
    end
  end
end
