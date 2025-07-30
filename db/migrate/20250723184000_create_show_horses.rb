# db/migrate/20250723184000_create_show_horses.rb
class CreateShowHorses < ActiveRecord::Migration[7.1]
  def change
    create_table :show_horses do |t|
      t.integer :Equipe_Show_ID, null: false
      t.integer :headnum, null: false
      t.text :horsename, null: false
      t.text :born_year, null: false
      t.text :FEI_ID, null: false
      t.text :Breed, null: false
      t.text :Breeder, null: false
      t.text :Sire, null: false
      t.text :color, null: false
      t.text :SireDam, null: false
      t.text :owner, null: false
      t.text :sex, null: false

      t.timestamps
    end

    add_index :show_horses, [:Equipe_Show_ID, :headnum], unique: true
  end
end
