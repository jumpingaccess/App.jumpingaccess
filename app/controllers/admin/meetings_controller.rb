# app/controllers/admin/meetings_controller.rb
class Admin::MeetingsController < ApplicationController
  layout "dashboard"
  before_action :require_login
  before_action :set_meeting, only: [:show, :videos, :start_stream, :stop_stream, :import_startlist]

  def show
    @concours = Competition.find(params[:id])
  end

  # ✅ Méthode simplifiée avec le nouveau service
  def classimport
    competition = Competition.find(params[:id])

    Rails.logger.debug "=== DÉBUT IMPORT CLASSES ==="

    begin
      service = EquipeImportService.new(competition)
      result = service.import_classes

      Rails.logger.debug "Résultat du service: #{result.inspect}"

      if result[:success]
        Rails.logger.debug "Import réussi, message: #{result[:message]}"
        redirect_to admin_meeting_path(competition.id),
                    notice: result[:message]
      else
        Rails.logger.debug "Import échoué, erreur: #{result[:error]}"
        redirect_to admin_meeting_path(competition.id),
                    alert: "Erreur d'import : #{result[:error]}"
      end
    rescue => e
      Rails.logger.error "Import classes error: #{e.message}"
      redirect_to admin_meeting_path(competition.id),
                  alert: "Erreur technique lors de l'import des épreuves"
    end
  end
  # ✅ Méthode simplifiée avec le nouveau service
  def horseimport
    competition = Competition.find(params[:id])

    begin
      service = EquipeImportService.new(competition)
      result = service.import_horses

      if result[:success]
        redirect_to admin_meeting_path(competition.id),
                    notice: result[:message]
      else
        redirect_to admin_meeting_path(competition.id),
                    alert: "Erreur d'import : #{result[:error]}"
      end
    rescue => e
      Rails.logger.error "Import horses error: #{e.message}"
      redirect_to admin_meeting_path(competition.id),
                  alert: "Erreur technique lors de l'import des chevaux"
    end
  end

  def videos
    @meeting = Competition.find(params[:id])
    @show_competitions = ShowCompetition.where(show_ID: @meeting.provider_competition_id).order(:datum)

    # Récupération des streams Castr
    streams_response = CastrApiService.fetch_streams
    @castr_streams = streams_response[:success] ? streams_response[:data] : { "docs" => [] }

    # Liste des pistes/arenas
    @pistes = ShowCompetition.where.not(arena: [nil, ""])
                             .where(show_ID: @meeting.provider_competition_id)
                             .distinct
                             .pluck(:arena)
                             .map { |a| { label: a } }
  end

  def start_stream
    begin
      StreamRouterService.start(params[:stream_url], params[:competition_id])
      redirect_to videos_admin_meeting_path(params[:id]),
                  notice: "Stream lancé avec succès."
    rescue => e
      Rails.logger.error "Start stream error: #{e.message}"
      redirect_to videos_admin_meeting_path(params[:id]),
                  alert: "Erreur lors du lancement du stream."
    end
  end

  def stop_stream
    begin
      StreamRouterService.stop(params[:stream_url])
      redirect_to videos_admin_meeting_path(params[:id]),
                  notice: "Stream arrêté avec succès."
    rescue => e
      Rails.logger.error "Stop stream error: #{e.message}"
      redirect_to videos_admin_meeting_path(params[:id]),
                  alert: "Erreur lors de l'arrêt du stream."
    end
  end

  def import_startlist
    class_id = params[:competition_id]

    begin
      service = EquipeImportService.new(@meeting)
      result = service.import_startlist(class_id)

      if result[:success]
        redirect_to videos_admin_meeting_path(params[:id]),
                    notice: result[:message]
      else
        redirect_to videos_admin_meeting_path(params[:id]),
                    alert: "Erreur d'import : #{result[:error]}"
      end
    rescue => e
      Rails.logger.error "Import startlist error: #{e.message}"
      redirect_to videos_admin_meeting_path(params[:id]),
                  alert: "Erreur technique lors de l'import de la liste de départs"
    end
  end

  private

  def set_meeting
    @meeting = Competition.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_dashboard_path, alert: "Meeting introuvable"
  end
end