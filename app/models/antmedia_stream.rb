class AntmediaStream < ApplicationRecord
  PROTOCOLS = %w[rtmp srt webrtc hls].freeze

  validates :proto, inclusion: { in: PROTOCOLS }, allow_nil: true

  validates :stream_name, presence: true


  before_create :generate_stream_key

  def rtmp?
    proto == "rtmp"
  end

  def srt?
    proto == "srt"
  end

  private

  def generate_stream_key
    if self.stream_key.blank?
      suffix = SecureRandom.alphanumeric(6)
      self.stream_key = "#{piste_name}_#{suffix}"
    end

    self.antmedia_stream_id = self.stream_key if self.antmedia_stream_id.blank?
  end
end
