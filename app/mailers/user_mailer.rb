# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
    def password_reset
      @user = params[:user]
      @url = edit_password_reset_url(token: @user.reset_password_token)
      mail(to: @user.email, subject: "Réinitialisation de votre mot de passe")
    end
  end