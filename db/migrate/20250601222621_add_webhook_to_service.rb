class AddWebhookToService < ActiveRecord::Migration[8.0]
  def change
    create_table :service_webhooks do |t|
      t.references :service, null: false, foreign_key: true
      t.string :url, null: false
      t.string :secret, null: false

      t.timestamps
    end

    add_index :service_webhooks, :url, unique: true
  end
end
