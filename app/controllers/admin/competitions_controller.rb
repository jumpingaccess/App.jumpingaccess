class Admin::CompetitionsController < ApplicationController
  layout "dashboard"
  before_action :require_login
  before_action :set_competition, only: [:edit, :update]

  def new
    @competition = Competition.new
  end

  def create
    @competition = Competition.new(competition_params)

    if @competition.save
      redirect_to admin_dashboard_path, notice: "Concours créé avec succès."
    else
      render :new
    end
  end
  def enable_timekeeping
    @competition = Competition.find(params[:id])

    begin
      TimekeepingIntegrationService.enable_competition_queue(@competition.id)
      redirect_to admin_meeting_path(@competition),
                  notice: "Chronométrage activé pour ce concours"
    rescue => e
      Rails.logger.error "Enable timekeeping error: #{e.message}"
      redirect_to admin_meeting_path(@competition),
                  alert: "Erreur lors de l'activation du chronométrage"
    end
  end

  def disable_timekeeping
    @competition = Competition.find(params[:id])

    begin
      TimekeepingIntegrationService.disable_competition_queue(@competition.id)
      redirect_to admin_meeting_path(@competition),
                  notice: "Chronométrage désactivé"
    rescue => e
      Rails.logger.error "Disable timekeeping error: #{e.message}"
      redirect_to admin_meeting_path(@competition),
                  alert: "Erreur lors de la désactivation"
    end
  end
  def show
    @competition = Competition.find(params[:id])
    # Ajoute la vue app/views/admin/competitions/show.html.erb si nécessaire
  end

  def edit
    # @competition est déjà chargé par before_action
  end

  def update
    if @competition.update(competition_params)
      redirect_to admin_competition_path(@competition), notice: "Concours mis à jour."
    else
      render :edit
    end
  end

  def search
    @query = params[:q]
    @competitions = Competition.where("name ILIKE ?", "%#{@query}%").limit(20)
    render :search_results # ou JSON si tu veux faire un dropdown live
  end

  def autocomplete
    query = params[:q].to_s.strip.downcase
    @competitions = Competition
                      .where("LOWER(name) LIKE :q OR LOWER(location) LIKE :q", q: "%#{query}%")
                      .limit(10)

    render partial: "autocomplete_results", formats: [:html]
  end

  private

  def set_competition
    @competition = Competition.find(params[:id])
  end

  def competition_params
    params.require(:competition).permit(
      :name, :location, :start_date, :end_date,
      :timezone, :fei_id, :logo, :public_enabled, :rabbitmq_enabled,
      :ftp_enabled, :ftp_host, :ftp_port, :ftp_user, :ftp_password, :ftp_path,
      :s3_enabled, :s3_bucket, :s3_region, :s3_access_key, :s3_secret_key, :country, :provider, :provider_competition_id,:enable_queue, :ffmpeg_quere_enabled
    )
  end
end
