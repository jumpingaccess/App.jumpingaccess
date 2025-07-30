class RenameStreamProtocolToProtoInAntmediaStreams < ActiveRecord::Migration[8.0]
  def change
  rename_column :antmedia_streams, :stream_protocol, :proto
  end
end
