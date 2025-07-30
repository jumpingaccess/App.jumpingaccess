class AddDetailsToCompetitions < ActiveRecord::Migration[8.0]
  def change
    add_column :competitions, :logo, :string
    add_column :competitions, :timezone, :string
    add_column :competitions, :fei_id, :string
    add_column :competitions, :public_enabled, :boolean
    add_column :competitions, :rabbitmq_enabled, :boolean
    add_column :competitions, :ftp_enabled, :boolean
    add_column :competitions, :ftp_host, :string
    add_column :competitions, :ftp_port, :integer
    add_column :competitions, :ftp_user, :string
    add_column :competitions, :ftp_password, :string
    add_column :competitions, :ftp_path, :string
    add_column :competitions, :s3_enabled, :boolean
    add_column :competitions, :s3_bucket, :string
    add_column :competitions, :s3_region, :string
    add_column :competitions, :s3_access_key, :string
    add_column :competitions, :s3_secret_key, :string
  end
end
