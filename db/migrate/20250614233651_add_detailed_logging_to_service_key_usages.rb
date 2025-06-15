class AddDetailedLoggingToServiceKeyUsages < ActiveRecord::Migration[8.0]
  def change
    add_column :service_key_usages, :user_agent, :text unless column_exists?(:service_key_usages, :user_agent)
    add_column :service_key_usages, :request_headers, :text unless column_exists?(:service_key_usages, :request_headers)
    add_column :service_key_usages, :request_body, :text unless column_exists?(:service_key_usages, :request_body)
    add_column :service_key_usages, :response_body, :text unless column_exists?(:service_key_usages, :response_body)
    add_column :service_key_usages, :response_headers, :text unless column_exists?(:service_key_usages, :response_headers)
    add_column :service_key_usages, :duration_ms, :integer unless column_exists?(:service_key_usages, :duration_ms)
    add_column :service_key_usages, :user_id, :bigint unless column_exists?(:service_key_usages, :user_id)
  end
end
