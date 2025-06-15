# frozen_string_literal: true

Rails.application.configure do
  # Schedule recurring API metrics batch job
  # This will run every 5 minutes to send aggregate metrics to StatsD/Grafana
  
  if Rails.env.production? || ENV['ENABLE_API_METRICS_SCHEDULER'] == 'true'
    Rails.application.config.after_initialize do
      # Schedule the first job and set up recurring execution
      ApiMetricsBatchJob.set(wait: 1.minute).perform_later
      
      # Use a simple approach with recurring jobs
      # In production, you might want to use cron or a more sophisticated scheduler
      Rails.logger.info "API Metrics Scheduler initialized - batch metrics will be sent every 5 minutes"
    end
  end
end