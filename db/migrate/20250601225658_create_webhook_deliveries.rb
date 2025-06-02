class CreateWebhookDeliveries < ActiveRecord::Migration[8.0]
  def change
    create_table :webhook_deliveries do |t|
      t.string :url
      t.string :event
      t.text :payload
      t.string :status
      t.integer :attempts
      t.datetime :last_attempt_at
      t.jsonb :response

      t.timestamps
    end
  end
end
