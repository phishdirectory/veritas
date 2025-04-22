# frozen_string_literal: true

# == Schema Information
#
# Table name: service_keys
#
#  id         :bigint           not null, primary key
#  api_key    :string           not null
#  hash_key   :string           not null
#  notes      :text
#  status     :string           default("active"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  service_id :bigint           not null
#
# Indexes
#
#  index_service_keys_on_api_key     (api_key) UNIQUE
#  index_service_keys_on_service_id  (service_id)
#
# Foreign Keys
#
#  fk_rails_...  (service_id => services.id)
#
#
# app/models/api_service/key.rb

class Service
  class Key < ApplicationRecord
    include AASM

    self.table_name = "service_keys" # Keep the same table name

    belongs_to :service
    has_many :usages, class_name: "Service::KeyUsage", dependent: :destroy

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
