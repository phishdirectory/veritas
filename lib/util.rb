# frozen_string_literal: true

module Util
  # also in ApplicationHelper for frontend use
  def self.commit_hash
    @commit_hash ||= begin
      commit_hash = `git rev-parse --short HEAD`.strip
      commit_hash.presence || "unknown"
    end

    @commit_hash
  end

  def self.commit_dirty?
    @commit_dirty ||= begin
      commit_dirty = `git status --porcelain`.strip.present?
      commit_dirty
    end
    @commit_dirty
  end

end
