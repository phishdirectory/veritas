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
    has_many :user_sessions, dependent: :destroy


    scope :impersonated, -> { where.not(impersonated_by_id: nil) }
    scope :not_impersonated, -> { where(impersonated_by_id: nil) }
    scope :expired, -> { where("expiration_at <= ?", Time.zone.now) }
    scope :not_expired, -> { where("expiration_at > ?", Time.zone.now) }
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

      update(last_seen_at: Time.zone.now)
    end

    def expired?
      expiration_at <= Time.zone.now
    end


  end

end
