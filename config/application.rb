require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Auth
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])
    config.autoload_paths += %W(#{config.root}/app/api)

    config.eager_load_paths += %W(#{config.root}/app/api)


    # TODO: Pre-load grape API
    # ::API::V3.compile!


    # console1984 / audits1984
    config.console1984.ask_for_username_if_empty = true
    config.console1984.incinerate = false

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # setting up ActiveRecord's encryption: https://guides.rubyonrails.org/active_record_encryption.html#setup
    # set vars from the credentials file
    config.active_record.encryption.primary_key = Rails.application.credentials.dig(:active_record, :encryption, :primary_key)
    config.active_record.encryption.deterministic_key = Rails.application.credentials.dig(:active_record, :encryption, :deterministic_key)
    config.active_record.encryption.key_derivation_salt = Rails.application.credentials.dig(:active_record, :encryption, :key_derivation_salt)

  end
end
