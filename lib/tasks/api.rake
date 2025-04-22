# File: lib/tasks/api.rake
# This file provides rake tasks to validate and inspect your API

namespace :api do
  desc "Validate the API structure and mount points"
  task validate: :environment do
    puts "Validating API structure..."

    # Check that the API modules/classes exist
    api_classes = [
      { klass: "Api::V1::API", description: "Main API class" },
      { klass: "Api::V1::Base", description: "Base API class" },
      { klass: "Api::V1::Auth", description: "Auth endpoints" },
      { klass: "Api::V1::Users", description: "Users endpoints" }
    ]

    api_classes.each do |api_class|
      klass_name = api_class[:klass]
      begin
        klass = klass_name.constantize
        puts "✅ #{klass_name} (#{api_class[:description]}) found."
      rescue NameError
        puts "❌ #{klass_name} (#{api_class[:description]}) not found. Make sure the class is defined correctly."
      end
    end

    # Check API routes
    puts "\nChecking API routes..."
    api_routes = Rails.application.routes.routes.select { |r| r.path.spec.to_s.include?("/api/") }

    if api_routes.any?
      puts "✅ Found #{api_routes.count} API routes."

      # Display some sample routes
      sample_routes = api_routes.first(5)
      puts "\nSample API routes:"
      sample_routes.each do |route|
        verb = route.verb.empty? ? "ANY" : route.verb
        puts "  #{verb.ljust(7)} #{route.path.spec}"
      end

      puts "  ..." if api_routes.count > 5
    else
      puts "❌ No API routes found. Make sure your API is properly mounted in config/routes.rb."
    end

    # Check for common API setup issues
    puts "\nChecking for common API setup issues..."

    # Check for autoload paths
    if Rails.application.config.autoload_paths.any? { |path| path.include?("/app/api") }
      puts "✅ API path is in autoload_paths."
    else
      puts "❌ API path is not in autoload_paths. Add this to config/application.rb:"
      puts "   config.autoload_paths += %W[#{Rails.root}/app/api]"
    end

    # Check for eager load paths
    if Rails.application.config.eager_load_paths.any? { |path| path.include?("/app/api") }
      puts "✅ API path is in eager_load_paths."
    else
      puts "❌ API path is not in eager_load_paths. Add this to config/application.rb:"
      puts "   config.eager_load_paths += %W[#{Rails.root}/app/api]"
    end

    puts "\nAPI validation complete."
  end

  desc "List all API endpoints"
  task endpoints: :environment do
    puts "Listing all API endpoints..."

    begin
      api = Api::V1::API.new
      routes = api.routes.map do |route|
        {
          method: route.request_method,
          path: route.path,
          description: route.description
        }
      end

      routes.each do |route|
        method = route[:method] || "ANY"
        puts "#{method.ljust(7)} #{route[:path].ljust(50)} #{route[:description]}"
      end

      puts "\nFound #{routes.count} API endpoints."
    rescue => e
      puts "❌ Failed to list API endpoints: #{e.message}"
      puts e.backtrace.first(5)
    end
  end

  desc "Test API health endpoint"
  task test_health: :environment do
    require 'net/http'

    puts "Testing API health endpoint..."

    begin
      uri = URI("http://localhost:3000/api/v1/health")
      response = Net::HTTP.get_response(uri)

      if response.code == "200"
        puts "✅ Health endpoint responded with 200 OK"
        puts "Response: #{response.body}"
      else
        puts "❌ Health endpoint returned status #{response.code}"
        puts "Response: #{response.body}"
      end
    rescue => e
      puts "❌ Failed to connect to health endpoint: #{e.message}"
    end
  end
end
