# app/controllers/admin/dashboard_controller.rb
class Admin::DashboardController < ApplicationController
  layout "dashboard"
  before_action :require_login

  #before_action :require_admin

  def index
    @competitions = Competition.order(start_date: :desc).page(params[:page]).per(6)
    render "home/index"
  end

  private


end