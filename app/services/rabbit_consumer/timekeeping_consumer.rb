# app/services/rabbit_consumer/timekeeping_consumer.rb
require 'bunny'

module RabbitConsumer
  class TimekeepingConsumer
    def initialize
      @connection = Bunny.new("amqp://jaccess:2good4u@192.168.1.130:5672")
      @connection.start
      @channel = @connection.create_channel
    end

    def start
      queues = Competition.where(enable_queue: true).includes(:show_competitions).flat_map do |meeting|
        meeting.show_competitions.map do |comp|
          "competition_queue_#{meeting.provider_competition_id}_#{comp.class_ID}"
        end
      end

      queues.each do |queue|
        @channel.queue(queue, durable: true).subscribe(manual_ack: true, block: false) do |delivery_info, _, payload|
          puts "📥 Message reçu sur #{queue}"

          begin
            TimekeepingParser.new(queue, payload).process
            @channel.ack(delivery_info.delivery_tag)
          rescue => e
            Rails.logger.error("❌ Erreur traitement message sur #{queue} : #{e.message}")
            Rails.logger.error(e.backtrace.join("\n"))
            @channel.reject(delivery_info.delivery_tag, false)
          end
        end
      end

      puts "✅ En attente de messages sur #{queues.size} queues..."

      # 👇 Blocage du thread principal pour que le service reste actif
      loop do
        sleep 1
      end
    end
  end
end
