# frozen_string_literal: true

class CreateServiceKeyUsages < ActiveRecord::Migration[8.0]
    def change
        create_table :service_key_usages do |t|
            t.references :key, null: false, foreign_key: { to_table: :service_keys }
            t.string :request_path
            t.string :request_method
            t.string :ip_address
            t.integer :response_code
            t.datetime :requested_at

            t.timestamps
        end

        add_index :service_key_usages, :requested_at
    end
end
