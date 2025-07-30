module Admin::StartsHelper
  def startlist_imported?(provider_show_id, class_id)
    StartsCompetition.exists?(Equipe_show_ID: provider_show_id, Equipe_class_ID: class_id)
  end
end