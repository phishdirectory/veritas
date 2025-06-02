# frozen_string_literal: true

# == Schema Information
#
# Table name: webhook_deliveries
#
#  id              :bigint           not null, primary key
#  attempts        :integer
#  event           :string
#  last_attempt_at :datetime
#  payload         :text
#  response        :jsonb
#  status          :string
#  url             :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
require "rails_helper"

RSpec.describe WebhookDelivery, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
