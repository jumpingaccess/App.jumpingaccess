# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
    def new
    end
  
    def create
      user = User.find_by(email: params[:email])
      if user
        if user&.authenticate(params[:password])
          session[:user_id] = user.id
          redirect_to admin_dashboard_path, notice: "Connecté avec succès."
        else
          flash.now[:alert] = "Adresse email ou mot de passe incorrect."
          redirect_to login_path, alert: "Adresse email ou mot de passe incorrect."
        end
      else 
        flash.now[:alert] = "Pas d'utilisateur connu."
        redirect_to login_path, alert: "Pas d'utilisateur connu."
      end
    end
  
    def destroy
      session[:user_id] = nil
      redirect_to login_path, notice: "Déconnecté."
    end
  end
  