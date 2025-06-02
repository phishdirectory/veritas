# frozen_string_literal: true

# == Schema Information
#
# Table name: service_webhooks
#
#  id         :bigint           not null, primary key
#  secret     :string           not null
#  url        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  service_id :bigint           not null
#
# Indexes
#
#  index_service_webhooks_on_service_id  (service_id)
#  index_service_webhooks_on_url         (url) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (service_id => services.id)
#
class Service
  class Webhook < ApplicationRecord
    belongs_to :service

    validates :url, presence: true
    validates :secret, presence: true

  end

end
