# frozen_string_literal: true

class BlazerChecksJob < ApplicationJob
  queue_as :low

  def perform(args)
    Blazer.run_checks(schedule: args[:schedule])
  end

end
