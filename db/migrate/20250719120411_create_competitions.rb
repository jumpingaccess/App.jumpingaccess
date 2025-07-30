class CreateCompetitions < ActiveRecord::Migration[8.0]
  def change
    create_table :competitions do |t|
      t.string :name
      t.string :location
      t.date :start_date
      t.date :end_date
      t.string :source
      t.string :external_id

      t.timestamps
    end
  end
end
