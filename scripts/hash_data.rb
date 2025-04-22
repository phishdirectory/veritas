# frozen_string_literal: true

require "dotenv/load"
require "openssl"
require "base64"
require "json"

# Your hash key from .env file
hash_key = ENV["HASH_KEY"]

# User data to encrypt
user_data = {
  "first_name"            => "Test",
  "last_name"             => "User",
  "email"                 => "test.user@example.co",
  "password"              => "Password123!",
  "password_confirmation" => "Password123!"
}

# Convert data to JSON string
json_data = user_data.to_json

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
hashed_data = Base64.strict_encode64(encrypted)

puts "Hashed data to use in Postman:"
puts hashed_data
