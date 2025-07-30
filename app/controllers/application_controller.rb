# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?
  before_action :set_competition
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    unless logged_in?
      redirect_to login_path, alert: "Vous devez être connecté pour accéder à cette page."
    end
  end
  
  private

  def set_competition
    if request.path =~ %r{^/admin/meeting/(\d+)}
      @meeting = Competition.find_by(id: $1)
    end
  end  
end
