# frozen_string_literal: true

# app/jobs/deliver_webhook_job.rb
class DeliverWebhookJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  def perform(webhook_url, payload, secret)
    delivery = WebhookDelivery.create!(
      url: webhook_url,
      event: payload[:event],
      payload: payload.to_json,
      status: "pending",
      attempts: 0
    )

    begin
      signature = generate_signature(payload.to_json, secret)

      connection = Faraday.new do |faraday|
        faraday.options.timeout = 10
        faraday.adapter Faraday.default_adapter
      end

      response = connection.post(webhook_url) do |req|
        req.headers["Content-Type"] = "application/json"
        req.headers["X-Webhook-Signature"] = signature
        req.headers["X-Webhook-Event"] = payload[:event]
        req.headers["User-Agent"] = "Veritas-Webhook/#{Veritas::VERSION}"
        req.body = payload.to_json
      end

      response_data = {
        status: response.status,
        headers: response.headers,
        body: response.body
      }

      delivery.update!(status: "delivered", attempts: delivery.attempts + 1, last_attempt_at: Time.current, response: response_data.to_json)
    rescue => e
      delivery.update!(status: "failed", attempts: delivery.attempts + 1, last_attempt_at: Time.current, response: e.to_json)
      raise e
    end
  end

  private

  def generate_signature(payload, secret)
    "sha256=#{OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), secret, payload)}"
  end

end
