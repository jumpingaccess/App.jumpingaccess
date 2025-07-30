class CreateCastrStreams < ActiveRecord::Migration[8.0]
  def change
    create_table :castr_streams do |t|
      t.integer :Equipe_show_ID
      t.text :Equipe_class_ID
      t.text :Start_ingest
      t.text :Stop_ingest
      t.text :TimeZone

      t.timestamps
    end
  end
end
