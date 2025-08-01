# app/models/antmedia_stream.rb
class AntmediaStream < ApplicationRecord
  PROTOCOLS = %w[rtmp srt webrtc hls].freeze

  validates :proto, inclusion: { in: PROTOCOLS }
  validates :stream_name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :stream_key, presence: true, uniqueness: true, length: { minimum: 3, maximum: 50 }
  validates :meeting_id, presence: true

  belongs_to :meeting, class_name: 'Competition', foreign_key: 'meeting_id', optional: true

  before_validation :generate_stream_key, on: :create
  before_validation :set_antmedia_stream_id, on: :create

  scope :for_meeting, ->(meeting_id) { where(meeting_id: meeting_id) }
  scope :by_protocol, ->(protocol) { where(proto: protocol) }

  def rtmp?
    proto == "rtmp"
  end

  def srt?
    proto == "srt"
  end

  def webrtc?
    proto == "webrtc"
  end

  def hls?
    proto == "hls"
  end

  def display_name
    "#{stream_name} (#{proto.upcase})"
  end

  def rtmp_url
    return nil unless rtmp?
    "rtmp://ott.jumpingaccess.com:1935/LiveApp/#{stream_key}"
  end

  after_save :sync_with_nodejs
  after_destroy :sync_with_nodejs

  private

  def sync_with_nodejs
    SyncTimekeepingConfigJob.perform_later if meeting&.rabbitmq_enabled?
  end

  def generate_stream_key
    return if stream_key.present?

    base_key = piste_name.present? ? piste_name.parameterize : 'stream'
    suffix = SecureRandom.alphanumeric(8)

    # S'assurer que la clé est unique
    loop do
      self.stream_key = "#{base_key}_#{suffix}"
      break unless AntmediaStream.exists?(stream_key: stream_key)
      suffix = SecureRandom.alphanumeric(8)
    end
  end

  def set_antmedia_stream_id
    self.antmedia_stream_id = stream_key if antmedia_stream_id.blank?
  end
end