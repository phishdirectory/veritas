# frozen_string_literal: true

Lockbox.master_key = Rails.application.credentials.dig(:lockbox, :master_key)
