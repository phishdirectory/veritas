# frozen_string_literal: true

class User
  class Session < ApplicationRecord
    has_paper_trail skip: [:session_token] # ciphertext columns will still be tracked
    has_encrypted :session_token
    blind_index :session_token

    belongs_to :user
    belongs_to :impersonated_by, class_name: "User", optional: true
    has_many :user_sessions, dependent: :destroy


    scope :impersonated, -> { where.not(impersonated_by_id: nil) }
    scope :not_impersonated, -> { where(impersonated_by_id: nil) }
    scope :expired, -> { where("expiration_at <= ?", Time.now) }
    scope :not_expired, -> { where("expiration_at > ?", Time.now) }
    scope :recently_expired_within, ->(date) { expired.where("expiration_at >= ?", date) }

    extend Geocoder::Model::ActiveRecord
    geocoded_by :ip
    after_validation :geocode, if: ->(session){ session.ip.present? and session.ip_changed? }

    def impersonated?
      !impersonated_by.nil?
    end

    LAST_SEEN_AT_COOLDOWN = 5.minutes

    def touch_last_seen_at
      return if last_seen_at&.after? LAST_SEEN_AT_COOLDOWN.ago # prevent spamming writes

      update_columns(last_seen_at: Time.now)
    end

    def expired?
      expiration_at <= Time.now
    end


  end

end
