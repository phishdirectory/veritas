# lib/clients/auth_client.rb
require "net/http"
require "openssl"
require "base64"
require "json"

module Clients
  class AuthClient
    attr_reader :api_key, :hash_key, :base_url

    def initialize(api_key, hash_key, base_url = "https://auth.phish.directory")
      @api_key = api_key
      @hash_key = hash_key
      @base_url = base_url
    end

    # Register a new user
    def create_user(user_data)
      hashed_data = hash_data(user_data)

      uri = URI("#{base_url}/api/v1/users")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      request = Net::HTTP::Post.new(uri.path)
      request["Content-Type"] = "application/json"
      request["X-Api-Key"] = api_key
      request.body = { hashed_data: hashed_data }.to_json

      response = http.request(request)
      JSON.parse(response.body)
    end

    # Authenticate a user
    def authenticate_user(email, password)
      credentials = { email: email, password: password }
      hashed_credentials = hash_data(credentials)

      uri = URI("#{base_url}/api/v1/auth/authenticate")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      request = Net::HTTP::Post.new(uri.path)
      request["Content-Type"] = "application/json"
      request["X-Api-Key"] = api_key
      request.body = { credentials: hashed_credentials }.to_json

      response = http.request(request)
      JSON.parse(response.body)
    end

    # Get user info by pd_id
    def get_user(pd_id)
      uri = URI("#{base_url}/api/v1/users/#{pd_id}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      request = Net::HTTP::Get.new(uri.path)
      request["X-Api-Key"] = api_key

      response = http.request(request)
      JSON.parse(response.body)
    end

    private

    # Hash data using the hash_key
    def hash_data(data)
      # Convert data to JSON
      json_data = data.to_json

      # Use OpenSSL to encrypt the data with the hash_key
      cipher = OpenSSL::Cipher.new("aes-256-cbc")
      cipher.encrypt

      # Create key and iv from the hash_key
      key = Digest::SHA256.digest(hash_key)[0...32]
      iv = hash_key[0...16].ljust(16, "0")

      cipher.key = key
      cipher.iv = iv

      # Encrypt the data
      encrypted = cipher.update(json_data) + cipher.final

      # Encode to base64
      Base64.strict_encode64(encrypted)
    end

  end
end
