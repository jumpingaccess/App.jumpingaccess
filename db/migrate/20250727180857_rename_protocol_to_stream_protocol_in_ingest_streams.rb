class RenameProtocolToStreamProtocolInAntmediaStreams < ActiveRecord::Migration[8.0]
  def change
   rename_column :antmedia_streams, :protocol, :stream_protocol

  end
end
