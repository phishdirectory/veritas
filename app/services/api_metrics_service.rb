# frozen_string_literal: true

class ApiMetricsService
  def self.record_request(usage_record)
    return unless usage_record

    # Basic request counter
    StatsD.increment("api.requests", tags: {
                       method: usage_record.request_method&.downcase,
                       endpoint: sanitize_endpoint(usage_record.request_path),
                       status: usage_record.response_code,
                       service: usage_record.key&.service&.name&.downcase
                     })

    # Response time metrics
    if usage_record.duration_ms
      StatsD.histogram("api.response_time", usage_record.duration_ms, tags: {
                         method: usage_record.request_method&.downcase,
                         endpoint: sanitize_endpoint(usage_record.request_path),
                         service: usage_record.key&.service&.name&.downcase
                       })
    end

    # Error tracking
    if usage_record.failed?
      StatsD.increment("api.errors", tags: {
                         method: usage_record.request_method&.downcase,
                         endpoint: sanitize_endpoint(usage_record.request_path),
                         status: usage_record.response_code,
                         service: usage_record.key&.service&.name&.downcase
                       })
    end

    # Record success rate (every 10th request to avoid too much data)
    return unless usage_record.id % 10 == 0

    calculate_and_record_success_rate
  end

  def self.record_endpoint_metrics(endpoint, method, duration_ms, status_code, service_name = nil)
    # Direct metric recording for real-time API calls
    StatsD.increment("api.requests",
                     tags: {
                       method: method&.downcase,
                       endpoint: sanitize_endpoint(endpoint),
                       status: status_code,
                       service: service_name&.downcase
                     })

    if duration_ms
      StatsD.histogram("api.response_time", duration_ms,
                       tags: {
                         method: method&.downcase,
                         endpoint: sanitize_endpoint(endpoint),
                         service: service_name&.downcase
                       })
    end

    return unless status_code && status_code >= 400

    StatsD.increment("api.errors",
                     tags: {
                       method: method&.downcase,
                       endpoint: sanitize_endpoint(endpoint),
                       status: status_code,
                       service: service_name&.downcase
                     })

  end

  def self.record_batch_metrics
    # Called periodically to send aggregate metrics
    time_range = 5.minutes.ago..Time.current

    # Total requests in the last 5 minutes
    total_requests = Service::KeyUsage.where(requested_at: time_range).count
    StatsD.gauge("api.total_requests_5min", total_requests)

    # Average response time in the last 5 minutes
    avg_response_time = Service::KeyUsage
                        .where(requested_at: time_range)
                        .where.not(duration_ms: nil)
                        .average(:duration_ms)

    if avg_response_time
      StatsD.gauge("api.avg_response_time_5min", avg_response_time.round(2))
    end

    # Success rate in the last 5 minutes
    successful_requests = Service::KeyUsage.where(requested_at: time_range).successful.count
    success_rate = total_requests > 0 ? (successful_requests.to_f / total_requests * 100).round(2) : 0
    StatsD.gauge("api.success_rate_5min", success_rate)

    # Error count in the last 5 minutes
    error_count = Service::KeyUsage.where(requested_at: time_range).failed.count
    StatsD.gauge("api.error_count_5min", error_count)
  end

  private

  def self.sanitize_endpoint(path)
    return "unknown" if path.blank?

    # Remove IDs and sensitive data from endpoints for better grouping
    path.gsub(/\/\d+/, "/ID")
        .gsub(/\/[a-f0-9-]{36}/, "/UUID")
        .gsub(/\/[a-f0-9]{32}/, "/HASH")
        .gsub(/\?.*/, "") # Remove query params
        .downcase
  end

  def self.calculate_and_record_success_rate
    # Calculate success rate for the last hour
    time_range = 1.hour.ago..Time.current
    total = Service::KeyUsage.where(requested_at: time_range).count

    return if total.zero?

    successful = Service::KeyUsage.where(requested_at: time_range).successful.count
    success_rate_value = (successful.to_f / total * 100).round(2)

    StatsD.gauge("api.success_rate", success_rate_value)
  end

end
