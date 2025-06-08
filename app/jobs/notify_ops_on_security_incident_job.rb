# frozen_string_literal: true

class NotifyOpsOnSecurityIncidentJob < ApplicationJob
  queue_as :default

  def perform(email:, input_type:, malicious_input:, ip_address: nil, user_agent: nil)
    OpsMailer.with(
      email: email,
      input_type: input_type,
      malicious_input: malicious_input,
      ip_address: ip_address,
      user_agent: user_agent,
      timestamp: Time.current
    ).security_incident.deliver_later
  end
end