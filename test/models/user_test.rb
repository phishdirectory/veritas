# == Schema Information
#
# Table name: users
#
#  id                                                              :bigint           not null, primary key
#  #<ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition :datetime
#  access_level                                                    :integer          default("user"), not null
#  email                                                           :string           not null
#  email_verified                                                  :boolean          default(FALSE)
#  email_verified_at                                               :datetime
#  first_name                                                      :string           not null
#  last_name                                                       :string           not null
#  locked_at                                                       :datetime
#  password_digest                                                 :string           not null
#  status                                                          :string           default("active"), not null
#  created_at                                                      :datetime         not null
#  updated_at                                                      :datetime         not null
#  pd_id                                                           :string           not null
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
