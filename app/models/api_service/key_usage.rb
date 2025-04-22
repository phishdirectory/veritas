# frozen_string_literal: true

module ApiService
  class KeyUsage < ApplicationRecord
    self.table_name = "service_key_usages" # Keep the same table name

    belongs_to :key, class_name: "ApiService::Key"

    validates :request_path, presence: true
    validates :request_method, presence: true
    validates :requested_at, presence: true

    before_validation :set_requested_at

    scope :recent, -> { order(requested_at: :desc) }

    private

    def set_requested_at
      self.requested_at ||= Time.current
    end

  end
end
