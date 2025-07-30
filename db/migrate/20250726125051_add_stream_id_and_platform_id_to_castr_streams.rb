class AddStreamIdAndPlatformIdToCastrStreams < ActiveRecord::Migration[8.0]
  def change
    add_column :castr_streams, :stream_id, :string
    add_column :castr_streams, :platform_id, :string
  end
end
