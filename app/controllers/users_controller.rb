class UsersController < ApplicationController
  layout "dashboard"
  before_action :require_login
  #before_action :require_admin  # si tu veux restreindre l'accès

  def index
    @users = User.order(:email)
  end
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to dashboard_path, notice: "Utilisateur créé avec succès."
    else
      flash.now[:alert] = "Erreur lors de la création."
      render :new
    end
  end
  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(user_params)
      redirect_to admin_dashboard_path, notice: "Profil mis à jour."
    else
      flash.now[:alert] = "Erreur lors de la mise à jour."
      render :edit
    end
  end 
  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :role)
  end

 
end