# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id         :bigint           not null, primary key
#  data       :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  session_id :string           not null
#
# Indexes
#
#  index_sessions_on_session_id  (session_id) UNIQUE
#  index_sessions_on_updated_at  (updated_at)
#
require "rails_helper"

RSpec.describe Session, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
