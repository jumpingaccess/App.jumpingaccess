class AddMeetingIdToAntmediaStreams < ActiveRecord::Migration[8.0]
  def change
    add_column :antmedia_streams, :meeting_id, :integer
  end
end
