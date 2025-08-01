# app/controllers/admin/starts_controller.rb
class Admin::StartsController < ApplicationController
  before_action :require_login

  def create
    meeting = Competition.find(params[:meeting_id])
    class_id = params[:class_id]

    # Validation des paramètres
    unless class_id.present?
      return redirect_to videos_admin_meeting_path(meeting),
                         alert: "ID de classe manquant"
    end

    begin
      # ✅ Utilisation du service amélioré
      service = EquipeImportService.new(meeting)
      result = service.import_startlist(class_id)

      if result[:success]
        redirect_to videos_admin_meeting_path(meeting),
                    notice: "📥 Épreuve #{class_id} : #{result[:message]}"
      else
        redirect_to videos_admin_meeting_path(meeting),
                    alert: "Erreur d'import : #{result[:error]}"
      end

    rescue => e
      Rails.logger.error "Import startlist error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      redirect_to videos_admin_meeting_path(meeting),
                  alert: "Erreur technique lors de l'import"
    end
  end

  def exists
    provider_id = params[:provider_id]
    class_id = params[:class_id]

    # Validation des paramètres
    unless provider_id.present? && class_id.present?
      return render json: {
        exists: false,
        error: "Paramètres manquants"
      }, status: :bad_request
    end

    begin
      exists = StartsCompetition.exists?(
        Equipe_show_ID: provider_id,
        Equipe_class_ID: class_id
      )

      render json: { exists: exists }
    rescue => e
      Rails.logger.error "Check exists error: #{e.message}"
      render json: {
        exists: false,
        error: "Erreur de vérification"
      }, status: :internal_server_error
    end
  end
end