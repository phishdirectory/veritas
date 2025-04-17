source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgres as the database for Active Record
gem 'pg', '~> 1.5', '>= 1.5.9'
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false
# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false
# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

gem 'aasm'
gem "friendly_id", "~> 5.5.1" # slugs
gem "hashid-rails", "~> 1.0" # obfuscate IDs in URLs

gem "sidekiq", "~> 7.3.8" # background jobs
gem "sidekiq-cron", "~> 2.1" # run Sidekiq jobs at scheduled intervals
gem "pg_search" # full-text search

gem "rack-cors" # manage CORS
gem "rack-attack" # rate limiting
gem "browser", "~> 6.2" # browser detection

# Pagination
gem "kaminari"
gem "api-pagination"

gem "flipper" # feature flags
gem "flipper-active_record"
gem "flipper-ui"

# API
gem "grape"
gem "grape-entity" # For Grape::Entity ( https://github.com/ruby-grape/grape-entity )
gem "grape-kaminari"
gem "grape-route-helpers"
gem "grape-swagger"
gem "grape-swagger-entity", "~> 0.5"

gem "webauthn", "~> 3.2"

gem "ahoy_matey" # analytics
gem "blazer" # business intelligence tool/dashboard

gem "rqrcode" # QR code generation

# todo: print pretty things in console
gem "awesome_print" # pretty print objects in console

gem "statsd-instrument", "~> 3.9"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  gem "rack-mini-profiler", "~> 3.3", require: false # performance profiling
  gem "stackprof" # used by `rack-mini-profiler` to provide flamegraphs
  gem "query_count"

end

group :development do
  gem "annotaterb"
  gem "actual_db_schema" # rolls back phantom migrations

   # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "listen", "~> 3.9"
  gem "web-console"

  gem "letter_opener_web" # preview emails

  gem "solargraph", require: false
  gem "solargraph-rails", "~> 0.2.0", require: false

  gem "htmlbeautifier", require: false # for https://marketplace.visualstudio.com/items?itemName=tomclose.format-erb

  gem "foreman"

  gem "bullet"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end

gem 'paper_trail'
gem "console1984"
gem "audits1984"

# IRB is pinned to 1.14.3 because Console1984 is incompatible with >=1.15.0.
# https://github.com/basecamp/console1984/issues/127
gem "irb", "~> 1.14.3"

gem "validates_email_format_of" # email address validations
