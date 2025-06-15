# frozen_string_literal: true

# == Schema Information
#
# Table name: service_key_usages
#
#  id               :bigint           not null, primary key
#  duration_ms      :integer
#  ip_address       :string
#  request_body     :text
#  request_headers  :text
#  request_method   :string
#  request_path     :string
#  requested_at     :datetime
#  response_body    :text
#  response_code    :integer
#  response_headers :text
#  user_agent       :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  key_id           :bigint           not null
#  user_id          :bigint
#
# Indexes
#
#  index_service_key_usages_on_duration_ms   (duration_ms)
#  index_service_key_usages_on_key_id        (key_id)
#  index_service_key_usages_on_requested_at  (requested_at)
#  index_service_key_usages_on_user_id       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (key_id => service_keys.id)
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
# # app/models/api_service/key_usage.rb
class Service
  class KeyUsage < ApplicationRecord
    self.table_name = "service_key_usages" # Keep the same table name

    belongs_to :key, class_name: "Service::Key"
    belongs_to :user, optional: true

    validates :request_path, presence: true
    validates :request_method, presence: true
    validates :requested_at, presence: true

    before_validation :set_requested_at

    scope :recent, -> { order(requested_at: :desc) }
    scope :slow_requests, ->(threshold_ms = 1000) { where("duration_ms > ?", threshold_ms) }
    scope :by_status_code, ->(code) { where(response_code: code) }
    scope :successful, -> { where(response_code: 200..299) }
    scope :failed, -> { where(response_code: 400..599) }

    def headers_hash
      return {} if request_headers.blank?

      JSON.parse(request_headers)
    rescue JSON::ParserError
      {}
    end

    def response_headers_hash
      return {} if response_headers.blank?

      JSON.parse(response_headers)
    rescue JSON::ParserError
      {}
    end

    def body_hash
      return {} if request_body.blank?

      JSON.parse(request_body)
    rescue JSON::ParserError
      {}
    end

    def response_hash
      return {} if response_body.blank?

      JSON.parse(response_body)
    rescue JSON::ParserError
      {}
    end

    def slow_request?(threshold_ms = 1000)
      duration_ms && duration_ms > threshold_ms
    end

    def successful?
      response_code && (200..299).include?(response_code)
    end

    def failed?
      response_code && (400..599).include?(response_code)
    end

    private

    def set_requested_at
      self.requested_at ||= Time.current
    end

  end

end
