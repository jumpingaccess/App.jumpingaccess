class CreateApiCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :api_credentials do |t|
      t.string :name
      t.string :api_key
      t.string :base_url
      t.string :auth_type

      t.timestamps
    end
  end
end
