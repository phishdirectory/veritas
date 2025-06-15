# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                       :bigint           not null, primary key
#  access_level             :integer          default("user"), not null
#  api_access_level         :integer          default("user"), not null
#  confirmation_sent_at     :datetime
#  confirmation_token       :string
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
#  index_users_on_confirmation_token  (confirmation_token) UNIQUE
#  index_users_on_email               (email) UNIQUE
#  index_users_on_pd_id               (pd_id) UNIQUE
#
class User < ApplicationRecord
  include AASM

  # set flipper id to pd_id
  def flipper_id
    pd_id
  end

  has_paper_trail
  has_secure_password

  has_many :visits, class_name: "Ahoy::Visit", dependent: :destroy
  has_many :user_sessions, class_name: "User::Session", dependent: :destroy
  has_one_attached :profile_photo

  # Define access level values centrally
  ACCESS_LEVELS = { user: 0, trusted: 1, admin: 2, superadmin: 3, owner: 4 }.freeze
  ACCESS_LEVEL_FIELDS = [:access_level, :api_access_level].freeze
  PRIMARY_ACCESS_LEVEL = :access_level # Define which field is the primary one

  # Define enums for all access level fields
  enum :access_level, ACCESS_LEVELS, scopes: false, default: :user # global access level
  enum :api_access_level, ACCESS_LEVELS, scopes: false, default: :user, prefix: :api # access level

  # Use virtual attributes to track which fields should be synced with global
  attr_accessor :api_access_level_synced

  # Callbacks to handle syncing
  before_create :set_default_access_levels
  before_save :sync_access_levels
  before_create :set_username
  after_update :notify_role_changes, if: :saved_change_to_access_level?
  after_create :send_confirmation_email

  scope :verified, -> { where(email_verified: true) }
  scope :unverified, -> { where(email_verified: false) }
  scope :last_seen_within, ->(ago) { joins(:user_sessions).where(user_sessions: { last_seen_at: ago.. }).distinct }
  scope :currently_online, -> { last_seen_within(15.minutes.ago) }
  scope :active, -> { last_seen_within(30.days.ago) }
  def active? = last_seen_at && (last_seen_at >= 30.days.ago)

  scope :user, -> { where(access_level: %i[user trusted admin superadmin owner]) }
  scope :trusted, -> { where(access_level: %i[trusted admin superadmin owner]) }
  scope :admin, -> { where(access_level: %i[admin superadmin owner]) }
  scope :superadmin, -> { where(access_level: %i[superadmin owner]) }
  scope :owner, -> { where(access_level: :owner) }

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true
  validates_email_format_of :email
  validates :email, undisposable: { message: "Sorry, but we do not accept disposable email providers." }
  normalizes :email, with: ->(email) { email.strip.downcase }
  validates :password, presence: true, length: { minimum: 8 }, if: lambda {
    new_record? || password.present?
  }
  validate :password_complexity, if: lambda {
    new_record? || password.present?
  }
  validates :pd_id, presence: true, uniqueness: true, length: { is: 11 }, format: {
    # format is PDU{digit}{7 alphanumeric characters}
    with: /\APDU\d[a-zA-Z0-9]{7}\z/,
    message: "must be in the format PDU{digit}{7 alphanumeric characters}"
  }
  validates :magic_link_token, uniqueness: true, allow_nil: true
  validates :profile_photo, content_type: { in: %w[image/jpeg image/jpeg image/png image/webp],
                                            message: "must be a JPEG, PNG, or WebP image"
},
                            size: { less_than: 5.megabytes, message: "must be less than 5MB" }

  before_validation :generate_pd_id, on: :create
  before_create :generate_confirmation_token

  # State machine for user status
  aasm column: :status do
    state :active, initial: true
    state :suspended
    state :deactivated

    event :suspend do
      transitions from: :active, to: :suspended
    end

    event :reactivate do
      transitions from: %i[suspended deactivated], to: :active
    end

    event :deactivate do
      transitions from: %i[active suspended], to: :deactivated
    end
  end

  ACCESS_LEVEL_FIELDS.each do |field|
    prefix = field == :access_level ? "" : "#{field.to_s.sub('_access_level', '')}_"

    # Define permission check methods
    define_method("#{prefix}trusted?") do
      result = %w[trusted admin superadmin owner].include?(send(field))
      # For access_level (primary field), also check pretend_is_not_admin
      field == :access_level ? result && !pretend_is_not_admin : result
    end

    define_method("#{prefix}admin?") do
      result = %w[admin superadmin owner].include?(send(field))
      # For access_level (primary field), also check pretend_is_not_admin
      field == :access_level ? result && !pretend_is_not_admin : result
    end

    define_method("#{prefix}superadmin?") do
      result = %w[superadmin owner].include?(send(field))
      # For access_level (primary field), also check pretend_is_not_admin
      field == :access_level ? result && !pretend_is_not_admin : result
    end

    define_method("#{prefix}owner?") do
      result = send(field) == "owner"
      # For access_level (primary field), also check pretend_is_not_admin
      field == :access_level ? result && !pretend_is_not_admin : result
    end

    # Skip generating role methods for access_level (they already exist)
    next if field == :access_level

    # Define methods to change access levels
    %w[trusted admin superadmin owner user].each do |role|
      method_name = role == "user" ? "remove_#{prefix}trusted!" : "make_#{prefix}#{role}!"

      define_method(method_name) do
        # Mark as not synced when explicitly changed
        sync_attr = "#{field}_synced"
        send("#{sync_attr}=", false) if respond_to?("#{sync_attr}=")

        update!(field => role)
      end
    end

    # Add reset method for non-primary fields
    define_method("reset_#{prefix}access_level!") do
      sync_attr = "#{field}_synced"
      send("#{sync_attr}=", true) if respond_to?("#{sync_attr}=")
      update!(field => access_level)
    end
  end

  def is_staff?
    staff
  end

  def is_pd_dev?
    pd_dev
  end

  def password_login_enabled?
    Flipper.enabled?(:password_login, self)
  end

  def can_authenticate?
    active? && !locked?
  end

  def email_verified?
    email_verified
  end

  def verify_email
    self.email_verified = true
    self.email_verified_at = Time.current
    self.confirmation_token = nil
    save!
  end

  def unverify_email
    self.email_verified = false
    self.email_verified_at = nil
    generate_confirmation_token
    save!
  end

  def send_confirmation_email
    generate_confirmation_token if confirmation_token.blank?
    self.confirmation_sent_at = Time.current
    save!
    EmailConfirmationJob.perform_later(self)
  end

  def generate_magic_link_token
    self.magic_link_token = SecureRandom.urlsafe_base64(32)
    self.magic_link_expires_at = 15.minutes.from_now
    self.magic_link_sent_at = Time.current
    self.magic_link_used_at = nil
    save!
  end

  def magic_link_valid?
    magic_link_token.present? &&
      magic_link_expires_at.present? &&
      magic_link_expires_at > Time.current &&
      magic_link_used_at.nil?
  end

  def consume_magic_link_token!
    return false unless magic_link_valid?

    self.magic_link_used_at = Time.current
    save!
    true
  end

  def send_magic_link
    generate_magic_link_token
    MagicLinkJob.perform_later(self)
  end

  def confirmation_period_valid?
    confirmation_sent_at && confirmation_sent_at > 5.minutes.ago
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def name
    full_name
  end

  def initials
    "#{first_name[0]}#{last_name[0]}"
  end

  def profile_photo_url(variant: :thumb)
    return nil unless profile_photo.attached?

    case variant
    when :thumb
      profile_photo.variant(resize_to_limit: [100, 100])
    when :medium
      profile_photo.variant(resize_to_limit: [200, 200])
    when :large
      profile_photo.variant(resize_to_limit: [400, 400])
    else
      profile_photo
    end
  end

  def has_profile_photo?
    profile_photo.attached?
  end

  # Public URL for external services to access profile photos or initials
  def public_profile_photo_url
    Rails.application.routes.url_helpers.user_profile_photo_url(pd_id: pd_id, **url_options)
  end

  def public_avatar_url(variant: :thumb)
    Rails.application.routes.url_helpers.user_avatar_url(pd_id: pd_id, variant: variant, **url_options)
  end

  # Direct URL to initials avatar (useful for external services that want to force initials)
  def public_initials_url(variant: :thumb)
    Rails.application.routes.url_helpers.user_initials_url(pd_id: pd_id, variant: variant, **url_options)
  end

  # Square profile photo URLs (explicit square shape)
  def public_avatar_square_url(variant: :thumb)
    Rails.application.routes.url_helpers.user_avatar_square_url(pd_id: pd_id, variant: variant, **url_options)
  end

  # Circle profile photo URLs (circular masked images)
  def public_avatar_circle_url(variant: :thumb)
    Rails.application.routes.url_helpers.user_avatar_circle_url(pd_id: pd_id, variant: variant, **url_options)
  end

  # Circle initials URL
  def public_initials_circle_url(variant: :thumb)
    Rails.application.routes.url_helpers.user_initials_circle_url(pd_id: pd_id, variant: variant, **url_options)
  end

  def is_impersonatable?(impersonator)
    # Cannot impersonate yourself
    return false if self == impersonator

    impersonator_level = ACCESS_LEVELS[impersonator.access_level.to_sym]
    target_level = ACCESS_LEVELS[access_level.to_sym]

    case impersonator.access_level.to_sym
    when :owner
      true # Owner can impersonate anyone (except themselves)
    when :superadmin
      !owner? # Superadmin can impersonate anyone except owner
    when :admin
      !admin? # Admin can only impersonate trusted and regular users
    else
      false # trusted and user levels cannot impersonate
    end
  end

  def is_viewable?(viewer)

    # you can view yourself
    return true if self == viewer

    viewer_level = ACCESS_LEVELS[viewer.access_level.to_sym]
    target_level = ACCESS_LEVELS[access_level.to_sym]

    case viewer.access_level.to_sym
    when :owner
      true # Owner can view anyone including themselves
    when :superadmin
      !owner? # Superadmin can view anyone except owner, including themselves
    when :admin
      !admin? # Admin can only view trusted and regular users, including themselves
    else
      false # trusted and user levels cannot view anyone
    end
  end


  def can_impersonate?
    # Determines if THIS user can impersonate others
    # Only active, non-pretending admins and above can impersonate
    return false unless can_authenticate? && !pretend_is_not_admin

    admin?
  end

  def impersonatable?
    # This is a convenience method for views - checks if user is impersonatable by the current admin
    # This should be overridden by passing current_user context, but provides basic check
    !admin?
  end

  def last_seen_at
    user_sessions.maximum(:last_seen_at)
  end

  def last_login_at
    user_sessions.maximum(:created_at)
  end

  def locked?
    locked_at.present?
  end

  def lock!
    update!(locked_at: Time.zone.now)

    # Invalidate all sessions
    user_sessions.destroy_all
  end

  def unlock!
    update!(locked_at: nil)
  end

  private

  def url_options
    case Rails.env
    when "development"
      { host: "localhost", port: 3000, protocol: "http" }
    when "staging"
      { host: "staging.veritas.phish.directory", protocol: "https" }
    when "production"
      { host: "veritas.phish.directory", protocol: "https" }
    else
      { host: "localhost", port: 3000, protocol: "http" }
    end
  end

  def set_username
    fname_length = first_name.length
    found = false
    username_to_check = nil

    # Progressively build username: jmayone, jamayone, jasmayone, etc.
    (1..fname_length).each do |i|
      username_to_check = "#{first_name[0, i].downcase}#{last_name.downcase}"
      next if User.exists?(username: username_to_check)

      self.username = username_to_check
      found = true
      break
    end

    return if found

    # Try full first name + last name as final attempt
    username_to_check = "#{first_name.downcase}#{last_name.downcase}"

    # All options taken: add error, queue job, abort
    errors.add(:base, "We've hit a snafu and your username seems to already be taken in our system. Operations will reach out within 24 business hours, and if you haven't heard from us at that point (very unlikely) you should email support@phish.directory")
    UsernameFailJob.perform_later(email: self.email, desired_username: username_to_check)
    throw(:abort)
  end


  def admin_override_pretend?
    ["admin"].include?(self.access_level)
  end

  def make_trusted!
    trusted!
  end

  def make_admin!
    admin!
  end

  def make_superadmin!
    superadmin!
  end

  def make_owner!
    owner!
  end

  def remove_trusted!
    user!
  end

  private

  def password_complexity
    return if password.blank?

    errors.add(:password, "must contain at least one uppercase letter") unless password.match(/[A-Z]/)
    errors.add(:password, "must contain at least one lowercase letter") unless password.match(/[a-z]/)
    errors.add(:password, "must contain at least one number") unless password.match(/\d/)
    errors.add(:password, "must contain at least one special character (!@#$%^&*()_+-=[]{}|;:,.<>?)") unless password.match(/[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/)
  end

  def invite_to_slack
    InviteToSlackJob.perform_later(self.email)
  end

  def send_welcome_email
    WelcomeEmailJob.perform_later(self)
  end

  def ops_new_user
    NotifyOpsOnNewUserJob.perform_later(self)
  end

  def notify_role_changes
    old_access_level = saved_change_to_access_level[0] || "user"
    new_access_level = saved_change_to_access_level[1] || "user"

    WebhookService.notify_user_role_changed(pd_id, new_access_level, old_access_level)
  end

  def set_default_access_levels
    # Initialize tracking attributes
    self.api_access_level_synced = true

    # No need to set access_level_synced since access_level is the primary field
    # No need to set access_level = access_level as it would be redundant

    # On creation, set API access level to match the primary
    self.api_access_level = access_level if api_access_level_synced
  end

  # Sync access levels when primary changes
  def sync_access_levels
    return unless access_level_changed?

    # No need to set access_level = access_level as it would be redundant

    # Update API access level if it's synced
    self.api_access_level = access_level if api_access_level_synced
  end


  def generate_pd_id
    # Generates global unique ID for the user
    # Format: PDU{random digit}{7 random hex characters}
    # EXAMPLE: PDU5A1B2C3D

    random_digits = SecureRandom.hex(4).upcase # Generates a random hex string of 8 characters
    numeric_first = rand(10).to_s # Generates a random digit 0-9
    remaining_chars = random_digits[0...7] # Take only 7 characters from the hex

    self.pd_id ||= "PDU#{numeric_first}#{remaining_chars}"
  end

  def generate_confirmation_token
    self.confirmation_token = SecureRandom.urlsafe_base64(32)
  end

end
