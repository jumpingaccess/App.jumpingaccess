class Admin::MonitoringController < ApplicationController
  layout "dashboard"
  before_action :require_login

  def index
    @stats = {
      total_competitions: Competition.count,
      enabled_competitions: Competition.where(enable_queue: true).count,
      total_classes: ShowCompetition.count,
      active_classes: active_classes_count
    }

    @recent_activity = recent_timekeeping_activity
    @system_status = check_system_status
  end

  def rabbitmq
    @rabbitmq_status = check_rabbitmq_connection
    @queues_info = get_queues_information

    # Statistiques additionnelles pour RabbitMQ
    @queue_stats = {
      total_queues: @queues_info.count,
      active_queues: @queues_info.count,
      total_competitions: Competition.where(enable_queue: true).count,
      pending_messages: 0 # À implémenter avec l'API RabbitMQ Management
    }

    respond_to do |format|
      format.html # Affiche la vue rabbitmq.html.erb
      format.json { render json: { status: @rabbitmq_status, queues: @queues_info, stats: @queue_stats } }
    end
  end

  def nodejs
    @nodejs_status = check_nodejs_status
    @consumer_info = get_consumer_information

    respond_to do |format|
      format.html
      format.json { render json: { status: @nodejs_status, info: @consumer_info } }
    end
  end

  def competitions
    @enabled_competitions = Competition.where(enable_queue: true)
                                       .includes(:show_competitions)

    @competition_stats = @enabled_competitions.map do |comp|
      {
        id: comp.id,
        name: comp.name,
        provider_competition_id: comp.provider_competition_id,
        classes_count: comp.show_competitions.count,
        status: comp.enable_queue ? 'active' : 'inactive',
        last_activity: last_activity_for_competition(comp.provider_competition_id)
      }
    end

    respond_to do |format|
      format.html
      format.json { render json: @competition_stats }
    end
  end

  def status
    # Endpoint AJAX pour les mises à jour en temps réel
    status_data = {
      timestamp: Time.current.iso8601,
      rabbitmq: check_rabbitmq_connection,
      nodejs: check_nodejs_status,
      competitions: Competition.where(enable_queue: true).count,
      active_queues: get_active_queues_count
    }

    render json: status_data
  end

  def send_command
    command = params[:command]

    begin
      case command
      when 'ping'
        result = send_rabbitmq_command({
                                         action: 'ping',
                                         timestamp: Time.current.iso8601,
                                         from: 'rails_monitoring'
                                       })
      when 'sync'
        result = send_rabbitmq_command({
                                         action: 'sync_competitions',
                                         timestamp: Time.current.iso8601,
                                         from: 'rails_monitoring'
                                       })
      when 'status'
        result = send_rabbitmq_command({
                                         action: 'get_status',
                                         timestamp: Time.current.iso8601,
                                         from: 'rails_monitoring'
                                       })
      else
        raise "Commande inconnue: #{command}"
      end

      render json: {
        success: true,
        message: "Commande '#{command}' envoyée",
        details: result
      }
    rescue => e
      Rails.logger.error "Erreur envoi commande RabbitMQ: #{e.message}"
      render json: {
        success: false,
        error: e.message
      }, status: 500
    end
  end



  private

  def send_rabbitmq_command(message)
    require 'bunny'

    rabbitmq_url = ENV['RABBITMQ_URL'] || 'amqp://jaccess:2good4u@192.168.1.130:5672'

    # Connexion à RabbitMQ
    connection = Bunny.new(rabbitmq_url)
    connection.start

    # Créer un canal
    channel = connection.create_channel

    # Déclarer la queue de commandes
    queue = channel.queue('rails_to_nodejs_commands', durable: true)

    # Publier le message
    channel.default_exchange.publish(
      message.to_json,
      routing_key: queue.name,
      persistent: true
    )

    Rails.logger.info "Message envoyé à RabbitMQ: #{message}"

    # Fermer la connexion
    connection.close

    {
      queue: queue.name,
      message: message,
      sent_at: Time.current
    }
  end


  def get_last_sync_from_cache
    # Vérifier si Node.js a fait un appel récent à l'API
    # On peut stocker cela dans Rails.cache quand l'API est appelée
    Rails.cache.read('nodejs_last_sync')
  end
  def active_classes_count
    Competition.joins(:show_competitions)
               .where(enable_queue: true)
               .count('show_competitions.id')
  end

  def recent_timekeeping_activity
    # Si vous avez un modèle Incident ou Activity
    # Incident.recent.limit(10)
    # Pour l'instant, retournons un tableau vide
    []
  end

  def check_system_status
    {
      rabbitmq: check_rabbitmq_connection,
      nodejs: check_nodejs_status,
      database: check_database_status,
      api: check_api_status
    }
  end

  def check_rabbitmq_connection
    begin
      # Test de connexion RabbitMQ via l'API de management ou ping
      rabbitmq_url = ENV['RABBITMQ_URL'] || 'amqp://jaccess:2good4u@192.168.1.130:5672'

      # Pour une vérification simple, on peut tester si l'URL est accessible
      uri = URI.parse(rabbitmq_url)

      # Test basique de connectivité
      socket = TCPSocket.new(uri.host, uri.port)
      socket.close

      {
        status: 'connected',
        host: uri.host,
        port: uri.port,
        last_check: Time.current
      }
    rescue => e
      {
        status: 'error',
        error: e.message,
        last_check: Time.current
      }
    end
  end



  def check_database_status
    begin
      ActiveRecord::Base.connection.execute('SELECT 1')
      {
        status: 'connected',
        last_check: Time.current
      }
    rescue => e
      {
        status: 'error',
        error: e.message,
        last_check: Time.current
      }
    end
  end

  def check_api_status
    begin
      # Test de l'API interne
      api_key = ENV['NODEJS_API_KEY']
      if api_key.present?
        {
          status: 'configured',
          api_key_present: true,
          last_check: Time.current
        }
      else
        {
          status: 'error',
          error: 'API key not configured',
          last_check: Time.current
        }
      end
    rescue => e
      {
        status: 'error',
        error: e.message,
        last_check: Time.current
      }
    end
  end

  def get_queues_information
    # Information sur les queues actives
    enabled_competitions = Competition.where(enable_queue: true)

    queues = []
    enabled_competitions.each do |comp|
      comp.show_competitions.each do |show_comp|
        queues << {
          name: "competition_queue_#{comp.provider_competition_id}_#{show_comp.class_ID}",
          competition: comp.name,
          class_name: show_comp.class_name,
          class_id: show_comp.class_ID
        }
      end
    end

    queues
  end

  def get_consumer_information
    {
      expected_queues: get_queues_information.count,
      # Autres infos du consumer à implémenter
    }
  end

  def get_active_queues_count
    get_queues_information.count
  end

  def last_activity_for_competition(provider_competition_id)
    # Si vous avez un modèle d'activité/incident
    # Incident.where(equipe_show_id: provider_competition_id).maximum(:created_at)
    nil
  end

  def get_last_sync_time
    # Timestamp de la dernière synchronisation
    # Pourrait être stocké en cache ou dans un modèle
    nil
  end

  def check_nodejs_status
    begin
      require 'net/http'

      # Appel au health check endpoint de Node.js
      uri = URI('http://localhost:3001/health')
      response = Net::HTTP.get_response(uri)

      if response.code == '200'
        health_data = JSON.parse(response.body)
        {
          status: 'connected',
          uptime: health_data['uptime'],
          active_queues: health_data['active_queues'],
          last_sync: health_data['last_sync'],
          rabbitmq_status: health_data['rabbitmq'],
          last_check: Time.current
        }
      else
        {
          status: 'error',
          error: "Health check failed with status #{response.code}",
          last_check: Time.current
        }
      end
    rescue Errno::ECONNREFUSED
      {
        status: 'disconnected',
        error: 'Consumer not running or health check server down',
        last_check: Time.current
      }
    rescue => e
      {
        status: 'error',
        error: e.message,
        last_check: Time.current
      }
    end
  end

end