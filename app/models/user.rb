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
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  pd_id                    :string           not null
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#  index_users_on_pd_id  (pd_id) UNIQUE
#
class User < ApplicationRecord
  include AASM

  # set flipper id to pd_id
  def flipper_id
    pd_id
  end

  has_paper_trail
  has_secure_password

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
  after_update :notify_role_changes, if: :saved_change_to_roles?
  after_create :invite_to_slack # todo: add condition that we should verify their email first
  after_create :send_welcome_email
  after_create :ops_new_user

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
  normalizes :email, with: ->(email) { email.strip.downcase }
  validates :password, presence: true, length: { minimum: 8 }, if: lambda {
    new_record? || password.present?
  }
  validates :pd_id, presence: true, uniqueness: true, length: { is: 11 }, format: {
    # format is PDU{digit}{7 alphanumeric characters}
    with: /\APDU\d[a-zA-Z0-9]{7}\z/,
    message: "must be in the format PDU{digit}{7 alphanumeric characters}"
  }

  before_validation :generate_pd_id, on: :create

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
      %w[trusted admin superadmin owner].include?(send(field))
    end

    define_method("#{prefix}admin?") do
      %w[admin superadmin owner].include?(send(field))
    end

    define_method("#{prefix}superadmin?") do
      %w[superadmin owner].include?(send(field))
    end

    define_method("#{prefix}owner?") do
      send(field) == "owner"
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

  def can_authenticate?
    active? && !locked?
  end

  def email_verified?
    email_verified
  end

  def verify_email
    self.email_verified = true
    self.email_verified_at = Time.current
    save!
  end

  def unverify_email
    self.email_verified = false
    self.email_verified_at = nil
    save!
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



  def trusted_or_higher?
    ["trusted", "admin", "superadmin", "owner"].include?(self.access_level) && !self.pretend_is_not_admin
  end

  def admin_or_higher?
    ["admin", "superadmin", "owner"].include?(self.access_level) && !self.pretend_is_not_admin
  end

  def superadmin_or_owner?
    ["superadmin", "owner"].include?(self.access_level) && !self.pretend_is_not_admin
  end

  def owner?
    access_level == "owner" && !self.pretend_is_not_admin
  end

  def admin_override_pretend?
    ["admin"].include?(self.access_level)
  end

  def can_impersonate?
    # Determines if THIS user can impersonate others
    # Only active, non-pretending admins and above can impersonate
    return false unless can_authenticate? && !pretend_is_not_admin

    admin_or_higher?
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
      !admin_or_higher? # Admin can only impersonate trusted and regular users
    else
      false # trusted and user levels cannot impersonate
    end
  end

  def impersonatable?
    # This is a convenience method for views - checks if user is impersonatable by the current admin
    # This should be overridden by passing current_user context, but provides basic check
    !admin_or_higher?
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
    old_roles = saved_change_to_roles[0] || []
    new_roles = saved_change_to_roles[1] || []

    WebhookService.notify_user_role_changed(pd_id, new_roles, old_roles)
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

end
