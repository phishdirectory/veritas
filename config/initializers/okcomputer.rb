# frozen_string_literal: true

# https://github.com/jphenow/okcomputer#registering-additional-checks
#
# class MyCustomCheck < OKComputer::Check
#   def call
#     if rand(10).even?
#       "Even is great!"
#     else
#       mark_failure
#       "We don't like odd numbers"
#     end
#   end
# end

OkComputer::Registry.register "database", OkComputer::ActiveRecordCheck.new
OkComputer::Registry.register "migrations", OkComputer::ActiveRecordMigrationsCheck.new
OkComputer::Registry.register "cache", OkComputer::CacheCheckSolidCache.new
OkComputer::Registry.register "ruby_version", OkComputer::RubyVersionCheck.new

# Only require authentication if credentials are available (not during asset precompilation)
if Rails.application.credentials.okcomputer.present?
  OkComputer.require_authentication(Rails.application.credentials.okcomputer[:username], Rails.application.credentials.okcomputer[:password], except: %w(default nonsecret))
end

# Run checks in parallel
OkComputer.check_in_parallel = true

# Mount at /healthchecks in config/routes.rb
OkComputer.mount_at = false

# Log when health checks are run
OkComputer.logger = Rails.logger
