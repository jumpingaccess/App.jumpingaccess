namespace :timekeeping do
  desc "Start the RabbitMQ consumer for timekeeping events"
  task consume: :environment do
    puts "🔄 Starting Timekeeping RabbitMQ consumer..."
    consumer = RabbitConsumer::TimekeepingConsumer.new
    consumer.start
  end
end
