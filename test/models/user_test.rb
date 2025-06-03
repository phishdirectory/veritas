# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                       :bigint           not null, primary key
#  access_level             :integer          default("user"), not null
#  api_access_level         :integer          default("user"), not null
#  email                    :string           not null
#  email_verified           :boolean          default(FALSE)
#  email_verified_at        :datetime
#  first_name               :string           not null
#  last_name                :string           not null
#  locked_at                :datetime
#  password_digest          :string           not null
#  pd_dev                   :boolean          default(FALSE), not null
#  pretend_is_not_admin     :boolean          default(FALSE), not null
#  services_used            :integer          default([]), is an Array
#  session_duration_seconds :integer          default(2592000), not null
#  signup_service           :integer
#  staff                    :boolean          default(FALSE), not null
#  status                   :string           default("active"), not null
#  username                 :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  pd_id                    :string           not null
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#  index_users_on_pd_id  (pd_id) UNIQUE
#
require "test_helper"

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
