# frozen_string_literal: true

# app/services/webhook_service.rb
class WebhookService
  def self.notify_user_role_changed(user_id, new_roles, old_roles = nil)
    # Services have_one webhook. Webhooks have a url and a secret.
    webhooks = Service.all.map(&:webhook)


    payload = {
      event: "user.role_changed",
      user_id: user_id,
      data: {
        new_roles: new_roles,
        old_roles: old_roles,
        timestamp: Time.current.iso8601
      }
    }

    webhooks.each do |webhook|
      DeliverWebhookJob.perform_later(webhook.url, payload, webhook.secret)
    end
  end


  def self.notify_user_updated(user_id, user_data)
    webhooks = Service.all.map(&:webhook)

    payload = {
      event: "user.updated",
      user_id: user_id,
      data: user_data.merge(timestamp: Time.current.iso8601)
    }

    webhooks.each do |webhook|
      DeliverWebhookJob.perform_later(webhook.url, payload, webhook.secret)
    end
  end

end
