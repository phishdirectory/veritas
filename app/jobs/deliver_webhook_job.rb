# frozen_string_literal: true

# app/jobs/deliver_webhook_job.rb
class DeliverWebhookJob < ApplicationJob
  queue_as :webhooks
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

      response = HTTParty.post(webhook_url,
                               headers: {
                                 "Content-Type"        => "application/json",
                                 "X-Webhook-Signature" => signature,
                                 "X-Webhook-Event"     => payload[:event],
                                 "User-Agent"          => "Veritas-Webhook/#{Veritas::VERSION}"
                               },
                               body: payload.to_json,
                               timeout: 10)

      delivery.update!(status: "delivered", attempts: delivery.attempts + 1, last_attempt_at: Time.current, response: response.to_json)
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
