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
require "test_helper"

class User::SessionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
