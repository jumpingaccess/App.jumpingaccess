class CreateEquipeIncidentWebhooks < ActiveRecord::Migration[8.0]
  def change
    create_table :equipe_incident_webhooks do |t|
      t.integer :equipe_show_id
      t.integer :equipe_class_id
      t.integer :hnr
      t.integer :startnb
      t.string :ridername
      t.string :horsename
      t.integer :phase_course
      t.integer :round_course
      t.string :type
      t.string :timestamp

      t.timestamps
    end
  end
end
