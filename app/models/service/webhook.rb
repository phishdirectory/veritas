# frozen_string_literal: true

class Service
  class Webhook < ApplicationRecord
    belongs_to :service

    validates :url, presence: true
    validates :secret, presence: true

  end

end
