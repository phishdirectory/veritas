# frozen_string_literal: true

class CreateServices < ActiveRecord::Migration[8.0]
    def change
      create_enum 'service_status', [
        'active',
        'suspended',
        'decommissioned'
      ]

        create_table :services do |t|
            t.string :name, null: false
            t.column :status, :service_status, null: false, default: 'active'

            t.timestamps
        end

        add_index :services, :name, unique: true
    end
end
