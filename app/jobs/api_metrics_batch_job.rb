# frozen_string_literal: true

class ApiMetricsBatchJob < ApplicationJob
  queue_as :default

  def perform
    # Send batch metrics to StatsD/Grafana every 5 minutes
    ApiMetricsService.record_batch_metrics

    # Schedule the next execution (recurring job pattern)
    if Rails.env.production? || ENV["ENABLE_API_METRICS_SCHEDULER"] == "true"
      self.class.set(wait: 5.minutes).perform_later
    end
  rescue => e
    Rails.logger.error("Failed to send batch metrics: #{e.message}")

    # Still schedule the next job even if this one failed
    if Rails.env.production? || ENV["ENABLE_API_METRICS_SCHEDULER"] == "true"
      self.class.set(wait: 5.minutes).perform_later
    end

    # Re-raise to ensure the job is marked as failed
    raise
  end

end
