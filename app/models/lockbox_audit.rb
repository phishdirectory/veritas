# frozen_string_literal: true

class LockboxAudit < ApplicationRecord
  belongs_to :subject, polymorphic: true
  belongs_to :viewer, polymorphic: true

end
