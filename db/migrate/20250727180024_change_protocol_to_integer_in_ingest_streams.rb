class ChangeProtocolToIntegerInAntmediaStreams < ActiveRecord::Migration[8.0]
  def change
      remove_column :antmedia_streams, :protocol, :string
    add_column :antmedia_streams, :protocol, :integer, default: 0, null: false
  
  end
end
