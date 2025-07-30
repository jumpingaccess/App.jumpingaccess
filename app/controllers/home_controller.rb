class HomeController < ApplicationController
  def index
     @competitions = Competition.order(start_date: :desc).page(params[:page]) || []
  end
end
