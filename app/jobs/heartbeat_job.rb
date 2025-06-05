# frozen_string_literal: true

class HeartbeatJob < ApplicationJob
  queue_as :priority

  def perform(*args)
    # Do something later
    StatsD.increment("heartbeat")
  end

end
