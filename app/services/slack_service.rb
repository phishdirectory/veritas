# frozen_string_literal: true

require "faraday"
require "json"

# app/services/slack_service.rb
class SlackService
  SLACK_API_URL = "https://phishdirectory.slack.com/api/users.admin.inviteBulk?_x_id=60102c21-1741311043.437&_x_csid=iSfBA4IqB14&slack_route=T07J9QT2P8R&_x_version_ts=1741300354&_x_frontend_build_type=current&_x_desktop_ia=4&_x_gantry=true&fp=7c&_x_num_retries=0"
  BOUNDARY = "----WebKitFormBoundaryBj3LlspRNf8aUHgB"

  def self.invite(email)
    xoxc = Rails.application.credentials.slack[:browser_token]
    xoxd = Rails.application.credentials.slack[:cookie]

    unless xoxc
      Rails.logger.error("ERROR: SLACK_BROWSER_TOKEN is required but not provided")
      raise "Missing required SLACK_BROWSER_TOKEN"
    end

    unless xoxd
      Rails.logger.error("ERROR: SLACK_COOKIE is required but not provided")
      raise "Missing required SLACK_COOKIE"
    end

    body = <<~BODY
      --#{BOUNDARY}\r
      Content-Disposition: form-data; name="token"\r
      \r
      #{xoxc}\r
      --#{BOUNDARY}\r
      Content-Disposition: form-data; name="invites"\r
      \r
      [{"email":"#{email}","type":"regular","mode":"manual"}]\r
      --#{BOUNDARY}\r
      Content-Disposition: form-data; name="team_id"\r
      \r
      T07J9QT2P8R\r
      --#{BOUNDARY}\r
      Content-Disposition: form-data; name="restricted"\r
      \r
      false\r
      --#{BOUNDARY}\r
      Content-Disposition: form-data; name="ultra_restricted"\r
      \r
      false\r
      --#{BOUNDARY}\r
      Content-Disposition: form-data; name="campaign"\r
      \r
      team_menu\r
      --#{BOUNDARY}\r
      Content-Disposition: form-data; name="_x_reason"\r
      \r
      submit-invite-to-workspace-invites\r
      --#{BOUNDARY}\r
      Content-Disposition: form-data; name="_x_mode"\r
      \r
      online\r
      --#{BOUNDARY}\r
      Content-Disposition: form-data; name="_x_sonic"\r
      \r
      true\r
      --#{BOUNDARY}\r
      Content-Disposition: form-data; name="_x_app_name"\r
      \r
      client\r
      --#{BOUNDARY}--\r
    BODY

    headers = {
      "Accept"       => "*/*",
      "Content-Type" => "multipart/form-data; boundary=#{BOUNDARY}",
      "Cookie"       => "d=#{xoxd}",
      "User-Agent"   => "Faraday/#{Faraday::VERSION}"
    }

    Rails.logger.info("Sending Slack invite for #{email}")

    begin
      response = Faraday.post(SLACK_API_URL, body, headers)
      Rails.logger.info("Slack API response status: #{response.status}")

      begin
        data = JSON.parse(response.body)
        Rails.logger.info("Slack API response data: #{data}")

        if data["ok"]
          Rails.logger.info("Successfully invited #{email} to Slack workspace")
          { success: true, data: data }
        else
          NotifyOpsOnSlackErrorJob.perform_later(email, data["error"])
          Rails.logger.error("Failed to invite #{email}: #{data['error'] || 'Unknown error'}")
          { success: false, error: data["error"], data: data }
        end
      rescue JSON::ParserError => e
        NotifyOpsOnSlackErrorJob.perform_later(email, e.message)
        Rails.logger.error("Error parsing Slack API response: #{e.message}")
        Rails.logger.error("Raw response: #{response.body[0..500]}#{'...' if response.body.length > 500}")
        { success: false, error: "Failed to parse response", details: e.message }
      end
    rescue => e
      NotifyOpsOnSlackErrorJob.perform_later(email, e.message)
      Rails.logger.error("Error sending invitation to Slack: #{e.message}")
      { success: false, error: "Request failed", details: e.message }
    end
  end

end
