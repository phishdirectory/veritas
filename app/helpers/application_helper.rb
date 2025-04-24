# frozen_string_literal: true

module ApplicationHelper
  include ActionView::Helpers

  def current_page?(path)
    request.path == path
  end

  def relative_timestamp(time, options = {})
    content_tag :span, "#{options[:prefix]}#{time_ago_in_words time} ago#{options[:suffix]}", options.merge(title: time)
  end

  def help_message
    content_tag :span, "Email #{help_email} for support.".html_safe # rubocop:disable Rails/OutputSafety
  end

  def help_email
    mail_to "support@phish.directory"
  end

  def commit_name
    @short_hash ||= commit_hash[0...7]
    @commit_name ||= begin
      if commit_dirty?
        "#{@short_hash}-dirty" # rubocop:disable Rails/HelperInstanceVariable
      else
        @short_hash # rubocop:disable Rails/HelperInstanceVariable
      end
    end
  end

  def commit_dirty?
    ::Util.commit_dirty?
  end

  def commit_hash
    ::Util.commit_hash
  end

  def commit_time
    @commit_time ||= begin
      git_time = `git log -1 --format=%at`.chomp

      return nil if git_time.blank?

      Time.zone.at(git_time.to_i) rescue nil # Convert the Unix epoch time to a Time object, handle error gracefully
    end

    @commit_time # rubocop:disable Rails/HelperInstanceVariable
  end

  def commit_duration
    @commit_duration ||= begin
      return nil if commit_time.nil?

      distance_of_time_in_words(commit_time, Time.zone.now)
    end

    @commit_duration # rubocop:disable Rails/HelperInstanceVariable
  end


  module_function :commit_hash, :commit_time

  def veritas_version
    @veritas_version ||= begin
      if Rails.env.development?
        "DEVELOPMENT"
      else
        env = Rails.env.upcase
        time = Time.now.utc.strftime("%Y-%m-%d %H-%M UTC")
        "#{env} @ #{time} (#{commit_name})"
      end
    end
  end

  def rails_version
    Rails::VERSION::STRING
  end

  def ruby_version
    RUBY_VERSION
  end

end
