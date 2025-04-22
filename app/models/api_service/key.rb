# frozen_string_literal: true

module ApiService
  class Key < ApplicationRecord
    include AASM

    self.table_name = "service_keys" # Keep the same table name

    belongs_to :service
    has_many :usages, class_name: "ApiService::KeyUsage", dependent: :destroy

    validates :api_key, presence: true, uniqueness: true
    validates :hash_key, presence: true
    validates :status, presence: true

    before_validation :generate_credentials, on: :create

    scope :active, -> { where(status: "active") }

    # State machine for key status
    aasm column: :status do
      state :active, initial: true
      state :deprecated   # Still works but is being phased out
      state :revoked      # No longer works at all

      event :deprecate do
        transitions from: :active, to: :deprecated
      end

      event :revoke do
        transitions from: %i[active deprecated], to: :revoked
      end
    end

    # Can this key be used for authentication?
    def may_use?
      active? || deprecated?
    end

    # Rotate this key (deprecate this one, create a new one)
    def rotate!(notes = nil)
      transaction do
        deprecate!
        new_key = service.generate_key("Rotated from key #{id}. #{notes}".strip)
        new_key
      end
    end

    private

    def generate_credentials
      self.api_key ||= SecureRandom.hex(24)
      self.hash_key ||= SecureRandom.hex(32)
    end

  end
end
