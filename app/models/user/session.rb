# frozen_string_literal: true

# == Schema Information
#
# Table name: user_sessions
#
#  id                       :bigint           not null, primary key
#  device_info              :string
#  expiration_at            :datetime         not null
#  fingerprint              :string
#  ip                       :string
#  last_seen_at             :datetime
#  latitude                 :float
#  longitude                :float
#  os_info                  :string
#  session_token_bidx       :string
#  session_token_ciphertext :string
#  signed_out_at            :datetime
#  string                   :string
#  timezone                 :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  impersonated_by_id       :bigint
#  user_id                  :bigint           not null
#
# Indexes
#
#  index_user_sessions_on_impersonated_by_id  (impersonated_by_id)
#  index_user_sessions_on_user_id             (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (impersonated_by_id => users.id)
#  fk_rails_...  (user_id => users.id)
#
class User
  class Session < ApplicationRecord
    has_paper_trail skip: [:session_token] # ciphertext columns will still be tracked
    has_encrypted :session_token
    blind_index :session_token

    belongs_to :user
    belongs_to :impersonated_by, class_name: "User", optional: true


    scope :impersonated, -> { where.not(impersonated_by_id: nil) }
    scope :not_impersonated, -> { where(impersonated_by_id: nil) }
    scope :expired, -> { where("expiration_at <= ?", Time.zone.now) }
    scope :not_expired, -> { where("expiration_at > ?", Time.zone.now) }
    scope :recently_expired_within, ->(date) { expired.where("expiration_at >= ?", date) }

    extend Geocoder::Model::ActiveRecord
    geocoded_by :ip
    after_validation :geocode, if: ->(session){ session.ip.present? and session.ip_changed? }

    # Location display helper
    def location_name
      if latitude.present? && longitude.present?
        "#{latitude.round(2)}, #{longitude.round(2)}"
      else
        "Unknown Location"
      end
    end

    # Map display data
    def map_data
      return nil unless latitude.present? && longitude.present?

      {
        latitude: latitude,
        longitude: longitude,
        tooltip: map_tooltip,
        color: session_color
      }
    end

    def impersonated?
      !impersonated_by.nil?
    end

    def touch_last_seen_at
      return if last_seen_at&.after? LAST_SEEN_AT_COOLDOWN.ago # prevent spamming writes

      update(last_seen_at: Time.zone.now)
    end

    def expired?
      expiration_at <= Time.zone.now
    end

    LAST_SEEN_AT_COOLDOWN = 5.minutes

    private

    def map_tooltip
      parts = []
      parts << "IP: #{ip}" if ip.present?
      parts << "Device: #{device_info}" if device_info.present?
      parts << "Created: #{created_at.strftime('%m/%d/%Y %I:%M %p')}"
      parts << "Status: #{expired? || signed_out_at ? 'Expired' : 'Active'}"
      parts.join("<br>")
    end

    def session_color
      if expired? || signed_out_at
        "#6B7280" # Gray for expired sessions
      elsif impersonated?
        "#F59E0B" # Orange for impersonated sessions
      else
        "#10B981" # Green for active sessions
      end
    end

  end

end
