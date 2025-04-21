# frozen_string_literal: true

# Be sure to restart your server when you modify this file.
# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.
# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow all phish.directory domains
    origins(/.*\.phish\.directory\z/)

    # Only allow API routes
    resource "/api/*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             expose: %w[X-Next-Page X-Offset X-Page X-Per-Page X-Prev-Page
                        X-Request-Id X-Runtime X-Total X-Total-Pages]
  end

  # Only in development environment, allow localhost
  if Rails.env.development?
    allow do
      origins "localhost:3000", "localhost:3001", "127.0.0.1:3000", "127.0.0.1:3001"

      resource "/api/*",
               headers: :any,
               methods: %i[get post put patch delete options head],
               expose: %w[X-Next-Page X-Offset X-Page X-Per-Page X-Prev-Page
                          X-Request-Id X-Runtime X-Total X-Total-Pages]
    end
  end
end
