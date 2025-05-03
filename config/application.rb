# frozen_string_literal: true

require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# app name should be InThisCase
module Veritas
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    config.mission_control.jobs.base_controller_class = "AdminController"
    config.mission_control.jobs.http_basic_auth_enabled = false
    config.audits1984.base_controller_class = "AdminController"
    config.console1984.incinerate = false
    config.console1984.protected_environments = %i[production test]
    config.console1984.production_data_warning = "You have access to production data here. That's a big deal. As part of our promise to keep customer data safe and private, we audit the commands you type here. Let's get started!"
    config.console1984.enter_unprotected_encryption_mode_warning = "Ok! You have access to encrypted information now. We pay extra close attention to any commands entered while you have this access. You can go back to protected mode with 'encrypt!' WARNING: Make sure you don't save objects that were loaded while in protected mode, as this can result in saving the encrypted texts."
    config.console1984.enter_protected_mode_warning	= "Great! You are back in protected mode. When we audit, we may reach out for a conversation about the commands you entered. What went well? Did you solve the problem without accessing personal data?"
    config.console1984.ask_for_username_if_empty = true
    config.console1984.incinerate = false
    config.console1984.protected_environments = %i[production staging]

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

  end
end
