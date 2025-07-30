  class Admin::AntmediaStreamsController < ApplicationController
    layout "dashboard"
    before_action :require_login
    before_action :set_meeting
    before_action :set_antmedia_stream, only: [:update, :destroy]

    def index
      @antmedia_streams = AntmediaStream.where(meeting_id: @meeting.id)
      @new_antmedia_stream = AntmediaStream.new

      client = Antmedia::Client.new
      response = client.list_streams
      #LoggerService.log_action("-", 'AntMedia', response)

      @remote_streams = response.success? ? JSON.parse(response.body) : []
    end

    def create
      @antmedia_stream = AntmediaStream.new(antmedia_stream_params)
      @antmedia_stream.meeting_id = @meeting.id
      client = Antmedia::Client.new

      if @antmedia_stream.save
        response = client.create_stream({
          name: @antmedia_stream.stream_name,
          streamId: @antmedia_stream.stream_key,
          type: @antmedia_stream.proto
        })

        unless response.success?
          @antmedia_stream.destroy
          flash[:error] = "Erreur AntMedia: #{response.body}"
        end

        redirect_to antmedia_admin_meeting_path(@meeting)
      else
        render :index
      end
    end

    def update
      client = Antmedia::Client.new

      if @antmedia_stream.update(antmedia_stream_params)
        client.update_stream(@antmedia_stream.antmedia_stream_id, {
          name: @antmedia_stream.stream_name,
          type: @antmedia_stream.proto
        })

        redirect_to antmedia_admin_meeting_path(@meeting), notice: "Stream mis à jour."
      else
        render :index
      end
    end

    def destroy
      client = Antmedia::Client.new
      client.delete_stream(@antmedia_stream.antmedia_stream_id)
      LoggerService.log_action("Destroy","Antmedia", "#{@antmedia_stream.antmedia_stream_id}" )
      @antmedia_stream.destroy
      redirect_to antmedia_admin_meeting_path(@meeting), notice: "Stream supprimé."
    end

    def edit
      head :ok
    end

    def import_antmedia
      LoggerService.log_action("Import", 'AntMedia',"🎯 Action import_antmedia appelée pour meeting ID #{@meeting.id}")
      client = Antmedia::Client.new
      response = client.list_streams
      
      if response.success?
        imported = 0
        #LoggerService.log_action("Import", 'AntMedia',"🌐 Réponse Antmedia : code=#{response.code}, body=#{response.body}")
        JSON.parse(response.body).each do |stream_data|
          stream_key = stream_data["streamId"]
          next if AntmediaStream.exists?(stream_key: stream_key)
          LoggerService.log_action("Import", 'AntMedia',"🌐 #{stream_key} /  #{stream_data.inspect}")

          created_stream = AntmediaStream.create(
            stream_name: stream_data["name"],
            stream_key: stream_key,
            antmedia_stream_id:  stream_key,
            proto: "rtmp",
            meeting_id: @meeting.id
          )

          if created_stream.persisted?
             LoggerService.log_action("Save To DB", 'AntMedia',"✅ Stream importé : #{created_stream.stream_name} (#{created_stream.stream_key})")
            imported += 1
          else
             LoggerService.log_action("Save To DB", 'AntMedia',"❌ Échec import stream : #{stream_data["name"]} - Erreurs: #{created_stream.errors.full_messages.join(', ')}")
          end
        end

        redirect_to antmedia_admin_meeting_path(@meeting), notice: "#{imported} stream(s) importé(s) depuis AntMedia."
      else
        redirect_to antmedia_admin_meeting_path(@meeting), alert: "Échec de l’import AntMedia: #{response.code}"
      end
    end

    private

    def set_meeting
      @meeting = Competition.find(params[:id])
    end

    def set_antmedia_stream
      @antmedia_stream = AntmediaStream.find(params[:stream_id])
    end
    def antmedia_stream_params
      params.require(:antmedia_stream).permit(:stream_name, :proto, :piste_name, :stream_key)
    end
  end
