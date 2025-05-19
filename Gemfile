# frozen_string_literal: true

source "https://rubygems.org"

ruby File.read(File.join(File.dirname(__FILE__), ".ruby-version")).strip

###############################################################################
# CORE RAILS AND PRIMARY DEPENDENCIES
###############################################################################
gem "rails", "~> 8.0.2"
gem "pg", "~> 1.5", ">= 1.5.9"           # PostgreSQL database
gem "puma", ">= 5.0"                     # Web server
gem "bootsnap", require: false           # Reduces boot times through caching
gem "kamal", require: false              # Docker container deployment
gem "thruster", require: false           # HTTP asset caching/compression and X-Sendfile acceleration
gem "faraday"                            # Web requests
gem "okcomputer" # Health checks

###############################################################################
# FRONTEND & UI
###############################################################################
gem "propshaft"                          # Modern asset pipeline
gem "importmap-rails"                    # JavaScript with ESM import maps
gem "turbo-rails"                        # Hotwire's SPA-like page accelerator
gem "stimulus-rails"                     # Hotwire's modest JavaScript framework
gem "tailwindcss-rails", "~> 4.2"        # CSS framework
gem "jbuilder"                           # Build JSON APIs

###############################################################################
# SECURITY & AUTHENTICATION
###############################################################################
gem "bcrypt", "~> 3.1.7"                 # Secure password hashing
gem "webauthn", "~> 3.2"                 # WebAuthn support
gem "rack-attack"                        # Rate limiting
gem "rack-cors"                          # CORS management
gem "validates_email_format_of"          # Email validation
gem "lockbox"                            # Encryption
gem "blind_index"                        # Encrypted search
gem "geocoder"

###############################################################################
# BACKGROUND PROCESSING & CACHING
###############################################################################
gem "redis"
gem "solid_queue"                        # Database-backed Active Job adapter
gem "solid_cable"                        # Database-backed Action Cable
gem "mission_control-jobs"               # Job monitoring

###############################################################################
# DATABASE TOOLS
###############################################################################
gem "pg_search"                          # Full-text search
gem "acts_as_paranoid", "~> 0.10.3"      # Soft deletions
gem "paper_trail", "~> 16.0.0"           # Track changes to models
gem "strong_migrations", "~> 2.3"        # Safer database migrations

###############################################################################
# URL & IDENTIFICATION
###############################################################################
gem "hashid-rails", "~> 1.0"             # Obfuscate IDs in URLs
gem "friendly_id", "~> 5.5.1"            # URL slugs

###############################################################################
# STATE MACHINES & ERROR HANDLING
###############################################################################
gem "aasm"                               # State machines
gem "safely_block"                       # Error handling

###############################################################################
# FILE & IMAGE PROCESSING
###############################################################################
gem "image_processing", "~> 1.2" # Active Storage image transformations
gem "active_storage_validations", "2.0.3" # File validations
gem "rqrcode" # QR code generation

###############################################################################
# EMAIL & COMMUNICATION
###############################################################################
gem "premailer-rails"                    # CSS to inline styles for emails
gem "email_reply_parser"                 # Parse email replies

###############################################################################
# BROWSER & SECURITY
###############################################################################
gem "browser", "~> 6.2"                  # Browser detection
gem "invisible_captcha"                  # Bot protection

###############################################################################
# MONITORING & ANALYTICS
###############################################################################
gem "ahoy_matey"                         # Analytics
gem "ahoy_email"                         # Email analytics
gem "blazer"                             # BI dashboard
gem "statsd-instrument", "~> 3.9"        # StatsD metrics
gem "audits1984"                         # Audit logging
gem "console1984"                        # Console access auditing
gem "irb", "~> 1.15.2"                   # IRB pinned for Console1984 compatibility

###############################################################################
# FEATURE FLAGS & CONFIGURATION
###############################################################################
gem "flipper"                            # Feature flags
gem "flipper-active_record"              # ActiveRecord adapter for Flipper
gem "flipper-ui"                         # UI for Flipper
gem "dotenv-rails"                       # Environment variables

###############################################################################
# PLATFORM COMPATIBILITY
###############################################################################
gem "tzinfo-data", platforms: %i[windows jruby]

##############################################################################
# API Documentation
##############################################################################
gem "rswag"
gem "rspec-rails"

###############################################################################
# DEVELOPMENT & TEST DEPENDENCIES
###############################################################################
group :development, :test do
  # Debugging
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  # Security & Code Quality
  gem "brakeman", require: false # Security analysis
  gem "rubocop-rails-omakase", require: false # Ruby styling
  gem "rubocop-capybara", "~> 2.22", ">= 2.22.1"
  gem "relaxed-rubocop"
  gem "overcommit", require: false # Git hooks

  # Performance
  gem "query_count" # SQL query counter

  # Code Quality
  gem "bullet" # N+1 query detection
end

group :development do
  # Development Tools
  gem "actual_db_schema"                 # Rolls back phantom migrations
  gem "annotaterb"                       # Annotate models
  gem "web-console"                      # Interactive console
  gem "listen", "~> 3.9"                 # File watcher
  gem "letter_opener_web"                # Preview emails
  gem "foreman"                          # Process manager
  gem "awesome_print"                    # Pretty print objects
  gem "rack-mini-profiler", "~> 3.3", require: false # Performance profiling
  gem "stackprof" # Used by rack-mini-profiler for flamegraphs

  # IDE Support
  gem "solargraph", require: false       # Ruby language server
  gem "solargraph-rails", "~> 1.1.0", require: false
  gem "htmlbeautifier", require: false   # ERB formatting
end

group :test do
  # System Testing
  gem "capybara"
  gem "selenium-webdriver"
end
