# frozen_string_literal: true

class HeartbeatJob < ApplicationJob
  def perform(*args)
    # Do something later
    StatsD.increment("heartbeat")
  end

end
