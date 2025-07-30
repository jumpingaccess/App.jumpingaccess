class AddEnableQueueToCompetitions < ActiveRecord::Migration[8.0]
  def change
    add_column :competitions, :enable_queue, :boolean, default: false, null: false
  end
end
