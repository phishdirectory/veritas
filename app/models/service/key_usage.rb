# frozen_string_literal: true

# == Schema Information
#
# Table name: service_key_usages
#
#  id             :bigint           not null, primary key
#  ip_address     :string
#  request_method :string
#  request_path   :string
#  requested_at   :datetime
#  response_code  :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  key_id         :bigint           not null
#
# Indexes
#
#  index_service_key_usages_on_key_id        (key_id)
#  index_service_key_usages_on_requested_at  (requested_at)
#
# Foreign Keys
#
#  fk_rails_...  (key_id => service_keys.id)
#
#
# # app/models/api_service/key_usage.rb
class Service
  class KeyUsage < ApplicationRecord
    self.table_name = "service_key_usages" # Keep the same table name

    belongs_to :key, class_name: "Service::Key"

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
