# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
#

puts "Seeding data..."

User.find_or_create_by!(email: "internal-service+auth@phish.directory") do |user|
  user.first_name = "Internal"
  user.last_name = "Service"
  user.password = Rails.application.credentials.dig(:owner_password)
  user.password_confirmation = Rails.application.credentials.dig(:owner_password)
  user.access_level = "owner"
  user.status = "active"
  user.email_verified = true
  user.email_verified_at = Time.current
end

User.find_or_create_by!(email: "jasper.mayone@phish.directory") do |user|
  user.first_name = "Jasper"
  user.last_name = "Mayone"
  user.password = Rails.application.credentials.dig(:owner_password)
  user.password_confirmation = Rails.application.credentials.dig(:owner_password)
  user.access_level = "owner"
  user.status = "active"
  user.email_verified = true
  user.email_verified_at = Time.current
end

puts "Seed data successfully created!"
