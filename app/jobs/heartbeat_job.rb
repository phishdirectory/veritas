# frozen_string_literal: true

class HeartbeatJob < ApplicationJob
  def perform(expected_queue = nil)
    queue = expected_queue.presence || self.queue_name.presence || "unknown"

    # if rails env is not development
    return unless Rails.env.development?


    # Send metric with queue in the name instead of as a tag
    StatsD.increment("heartbeat.#{queue}")

  end

end
