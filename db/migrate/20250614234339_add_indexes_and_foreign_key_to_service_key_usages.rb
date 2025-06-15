class AddIndexesAndForeignKeyToServiceKeyUsages < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :service_key_usages, :user_id, algorithm: :concurrently unless index_exists?(:service_key_usages, :user_id)
    add_index :service_key_usages, :duration_ms, algorithm: :concurrently unless index_exists?(:service_key_usages, :duration_ms)
    add_foreign_key :service_key_usages, :users, column: :user_id, on_delete: :nullify, validate: false unless foreign_key_exists?(:service_key_usages, :users, column: :user_id)
  end
end
