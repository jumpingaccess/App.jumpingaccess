class CreateAntmediaStreams < ActiveRecord::Migration[8.0]
  def change
    create_table :antmedia_streams do |t|
      t.string :stream_name, null: false
      t.string :stream_key, null: false
      t.string :antmedia_stream_id
      t.string :piste_name
      t.string :proto, null: false, default: "rtmp"
      t.timestamps
    end
  end
end