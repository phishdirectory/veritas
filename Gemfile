# frozen_string_literal: true

source "https://rubygems.org"

##############################################################################
# Rails Core and Server
##############################################################################
gem "rails", "~> 8.0.2"
gem "pg", "~> 1.5", ">= 1.5.9" # PostgreSQL database
gem "puma", ">= 5.0"                      # Web server
gem "bootsnap", require: false            # Reduces boot times through caching
gem "tzinfo-data", platforms: %i[windows jruby]

##############################################################################
# Frontend and Asset Pipeline
##############################################################################
gem "propshaft"                           # Modern asset pipeline
gem "importmap-rails"                     # JavaScript with ESM import maps
gem "turbo-rails"                         # Hotwire's page accelerator
gem "stimulus-rails"                      # Hotwire's JavaScript framework
gem "jbuilder"                            # JSON API builder

##############################################################################
# Authentication and Security
##############################################################################
gem "bcrypt", "~> 3.1.7"                  # Secure password hashing
gem "webauthn", "~> 3.2"                  # WebAuthn support
gem "rack-attack"                         # Rate limiting
gem "rack-cors"                           # CORS management
gem "validates_email_format_of"           # Email validation

##############################################################################
# Database and Data Management
##############################################################################
gem "aasm"                                # State machines
gem "friendly_id", "~> 5.5.1"             # URL slugs
gem "hashid-rails", "~> 1.0"              # Obfuscate IDs in URLs
gem "pg_search"                           # Full-text search
gem "paper_trail"                         # Record changes to models
gem "lockbox"                             # Encryption
gem "blind_index"                         # Encrypted search

##############################################################################
# Background Processing and Scheduled Jobs
##############################################################################
gem "solid_queue" # Database-backed Active Job adapter
gem "mission_control-jobs" # Job monitoring

##############################################################################
# Caching and Performance
##############################################################################
gem "redis"                               # Redis client
gem "solid_cache"                         # Database-backed Rails.cache
gem "solid_cable"                         # Database-backed Action Cable
gem "thruster", require: false            # HTTP asset caching/compression

##############################################################################
# Monitoring, Analytics and Insights
##############################################################################
gem "ahoy_matey"                          # Analytics
gem "ahoy_email"                          # Email analytics
gem "blazer"                              # BI dashboard
gem "statsd-instrument", "~> 3.9"         # StatsD metrics
gem "audits1984"                          # Audit logging
gem "console1984"                         # Console access auditing
gem "irb", "~> 1.15.2"                    # IRB pinned for Console1984 compatibility

##############################################################################
# Feature Management
##############################################################################
gem "flipper"                             # Feature flags
gem "flipper-active_record"               # ActiveRecord adapter for Flipper
gem "flipper-ui"                          # UI for Flipper

##############################################################################
# Utilities
##############################################################################
gem "browser", "~> 6.2"                   # Browser detection
gem "rqrcode"                             # QR code generation
gem "awesome_print"                       # Pretty print objects
gem "kamal", require: false               # Docker deployment
gem "dotenv-rails"                        # Environment variables

##############################################################################
# API Documentation
##############################################################################

##############################################################################
# Development and Test Dependencies
##############################################################################
group :development, :test do
  # Debugging
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  # Code Quality and Security
  gem "brakeman", require: false # Security analysis
  gem "rubocop-rails-omakase", require: false # Ruby styling
  gem "rubocop-capybara", "~> 2.22", ">= 2.22.1"
  gem "rubocop-rspec", "~> 3.6"
  gem "rubocop-rspec_rails", "~> 2.31"
  gem "relaxed-rubocop"
  gem "overcommit", require: false # Git hooks

  # Performance
  gem "query_count"                       # SQL query counter
  gem "rack-mini-profiler", "~> 3.3", require: false
  gem "stackprof"                         # Used by rack-mini-profiler

  # Code Quality
  gem "bullet" # N+1 query detection

  # Testing
  gem "rspec-rails"
  gem "rswag-specs"
end

group :development do
  # Development Tools
  gem "actual_db_schema"                  # Rolls back phantom migrations
  gem "annotaterb"                        # Annotate models
  gem "web-console"                       # Interactive console
  gem "listen", "~> 3.9"                  # File watcher
  gem "letter_opener_web"                 # Preview emails
  gem "foreman"                           # Process manager

  # IDE Support
  gem "solargraph", require: false        # Ruby language server
  gem "solargraph-rails", "~> 1.1.0", require: false
  gem "htmlbeautifier", require: false    # ERB formatting
end

group :test do
  # System Testing
  gem "capybara"
  gem "selenium-webdriver"
end
