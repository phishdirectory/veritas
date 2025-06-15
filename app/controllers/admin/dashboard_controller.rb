# frozen_string_literal: true

class Admin::DashboardController < Admin::BaseController
  def index
    # Admin dashboard stats
    @services_count = Service.count
    @users_count = User.count
    @admin_count = User.admin.count

    # API metrics data
    prepare_api_metrics
  end

  private

  def prepare_api_metrics
    # Time range for charts (last 24 hours by default)
    time_range = 24.hours.ago..Time.current

    # Requests over time (hourly for last 24 hours)
    @requests_over_time = Service::KeyUsage
                          .where(requested_at: time_range)
                          .group_by_hour(:requested_at)
                          .count

    # Response time trends (average per hour)
    @response_time_trends = Service::KeyUsage
                            .where(requested_at: time_range)
                            .where.not(duration_ms: nil)
                            .group_by_hour(:requested_at)
                            .average(:duration_ms)
                            .transform_values { |v| v&.round(2) }

    # Status code distribution (last 24 hours)
    @status_code_distribution = Service::KeyUsage
                                .where(requested_at: time_range)
                                .group(:response_code)
                                .count

    # Top endpoints by volume (last 24 hours)
    @top_endpoints = Service::KeyUsage
                     .where(requested_at: time_range)
                     .group(:request_path)
                     .count
                     .sort_by { |_, v| -v }
                     .first(10)
                     .to_h

    # API performance summary
    @api_summary = calculate_api_summary(time_range)

    # Error rate over time
    @error_rate_over_time = calculate_error_rate_over_time(time_range)
  end

  def calculate_api_summary(time_range)
    usage_data = Service::KeyUsage.where(requested_at: time_range)

    {
      total_requests: usage_data.count,
      avg_response_time: usage_data.where.not(duration_ms: nil).average(:duration_ms)&.round(2) || 0,
      success_rate: calculate_success_rate(usage_data),
      slow_requests: usage_data.slow_requests.count
    }
  end

  def calculate_success_rate(usage_data)
    total = usage_data.count
    return 0 if total.zero?

    successful = usage_data.successful.count
    ((successful.to_f / total) * 100).round(2)
  end

  def calculate_error_rate_over_time(time_range)
    # Calculate error rate per hour
    all_requests_by_hour = Service::KeyUsage
                           .where(requested_at: time_range)
                           .group_by_hour(:requested_at)
                           .count

    error_requests_by_hour = Service::KeyUsage
                             .where(requested_at: time_range)
                             .failed
                             .group_by_hour(:requested_at)
                             .count

    all_requests_by_hour.map do |hour, total|
      errors = error_requests_by_hour[hour] || 0
      [hour, total.zero? ? 0 : ((errors.to_f / total) * 100).round(2)]
    end.to_h
  end

end
