# app/jobs/trigger_ffmpeg_job.rb
class TriggerFfmpegJob < ApplicationJob
  queue_as :default

  def perform(payload)
    connection = Bunny.new("amqp://jaccess:2good4u@192.168.1.130:5672")
    connection.start
    channel = connection.create_channel
    queue = channel.queue("ffmpeg_recording_trigger", durable: true)
    queue.publish(payload.to_json, persistent: true)
    channel.close
    connection.close

    Rails.logger.info("🎬 Trigger sent to ffmpeg_recording_trigger: #{payload.inspect}")
  rescue => e
    Rails.logger.error("❌ Failed to send FFMPEG trigger: #{e.message}")
  end
end
