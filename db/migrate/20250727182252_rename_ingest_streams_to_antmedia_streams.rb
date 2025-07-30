class RenameAntmediaStreamsToAntmediaStreams < ActiveRecord::Migration[8.0]
  def change
     rename_table :antmedia_streams, :antmedia_streams
  end
end
