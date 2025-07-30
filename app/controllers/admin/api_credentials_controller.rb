class Admin::ApiCredentialsController < ApplicationController
  layout "dashboard"
  before_action :require_login
  before_action :set_api_credential, only: [:edit, :update, :destroy]

  def index
    @api_credentials = ApiCredential.all
  end

  def new
    @api_credential = ApiCredential.new
  end
  def self.for_provider(name)
    where("LOWER(name) = ?", name.downcase).first
  end
  def create
    @api_credential = ApiCredential.new(api_credential_params)
    if @api_credential.save
      redirect_to admin_api_credentials_path, notice: "Clé API ajoutée avec succès."
    else
      render :new
    end
  end

  def edit; end

  def update
    if @api_credential.update(api_credential_params)
      redirect_to admin_api_credentials_path, notice: "Clé API mise à jour."
    else
      render :edit
    end
  end

  def destroy
    @api_credential.destroy
    redirect_to admin_api_credentials_path, notice: "Clé API supprimée."
  end

  private

  def set_api_credential
    @api_credential = ApiCredential.find(params[:id])
  end

  def api_credential_params
    params.require(:api_credential).permit(:name, :auth_type, :api_key, :base_url)
  end
end
