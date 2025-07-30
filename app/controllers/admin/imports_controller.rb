class Admin::ImportsController <  ApplicationController
  layout "dashboard"
  before_action :require_login
  #before_action :require_admin    
  def equipe
    # Afficher page ou lancer import JSON depuis Equipe
  end

  def hippodata
    # Afficher page ou lancer import JSON depuis Hippodata
  end

  def destroy
    type = params[:type] # "classes" ou "horses"
    id = params[:id].to_i

    case type
    when 'classes'
      concours = Competition.find_by(id: id)
      if concours
        ShowCompetition.where(show_ID: concours.provider_competition_id).delete_all
        flash[:notice] = "Toutes les épreuves importées ont été supprimées."
      else
        flash[:alert] = "Concours introuvable pour suppression des épreuves."
      end
    when 'horses'
      concours = Competition.find_by(id: id)
      if concours
        ShowHorse.where(Equipe_Show_ID: concours.provider_competition_id).delete_all
        flash[:notice] = "Tous les chevaux importés ont été supprimés."
      else
        flash[:alert] = "Concours introuvable pour suppression des chevaux."
      end
    else
      flash[:alert] = "Type d'importation invalide."
    end

    redirect_to admin_meeting_path(id)
  end  
end