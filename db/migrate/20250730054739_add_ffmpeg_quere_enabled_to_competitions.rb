class AddFfmpegQuereEnabledToCompetitions < ActiveRecord::Migration[8.0]
  def change
    add_column :competitions, :ffmpeg_quere_enabled, :boolean
  end
end
