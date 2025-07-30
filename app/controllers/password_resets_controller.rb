# app/controllers/password_resets_controller.rb
class PasswordResetsController < ApplicationController
    def new
    end
  
    def create
      user = User.find_by(email: params[:email])
      if user
        user.generate_reset_token!
        UserMailer.with(user: user).password_reset.deliver_now
      end
      redirect_to login_path, notice: "Si cet email existe, un lien de réinitialisation a été envoyé."
    end
  
    def edit
      @user = User.find_by(reset_password_token: params[:token])
      redirect_to new_password_reset_path, alert: "Lien invalide ou expiré." unless @user&.reset_token_valid?
    end
  
    def update
      @user = User.find_by(reset_password_token: params[:token])
      if @user&.reset_token_valid? && @user.update(password_params)
        @user.clear_reset_token!
        redirect_to login_path, notice: "Mot de passe mis à jour."
      else
        flash.now[:alert] = "Impossible de mettre à jour le mot de passe."
        render :edit
      end
    end
  
    private
  
    def password_params
      params.require(:user).permit(:password, :password_confirmation)
    end
  end
  