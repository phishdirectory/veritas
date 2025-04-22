# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                :bigint           not null, primary key
#  access_level      :integer          default("user"), not null
#  email             :string           not null
#  email_verified    :boolean          default(FALSE)
#  email_verified_at :datetime
#  first_name        :string           not null
#  last_name         :string           not null
#  locked_at         :datetime
#  password_digest   :string           not null
#  status            :string           default("active"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  pd_id             :string           not null
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#  index_users_on_pd_id  (pd_id) UNIQUE
#
# app/models/user.rb
class User < ApplicationRecord
  include AASM

  has_paper_trail
  has_secure_password

  # has_encrypted

  scope :verified, -> { where(email_verified: true) }
  scope :unverified, -> { where(email_verified: false) }

  scope :user, -> { where(access_level: %i[user trusted admin superadmin owner]) }
  scope :trusted, -> { where(access_level: %i[trusted admin superadmin owner]) }
  scope :admin, -> { where(access_level: %i[admin superadmin owner]) }
  scope :superadmin, -> { where(access_level: %i[superadmin owner]) }
  scope :owner, -> { where(access_level: :owner) }

  enum :access_level, { user: 0, trusted: 1, admin: 2, superadmin: 3, owner: 4 },
       scopes: false, default: :user

  # has_many :user_sessions, dependent: :destroy

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

  # scope :last_seen_within, ->(ago) { joins(:user_sessions).where(user_sessions: { last_seen_at: ago.. }).distinct }
  # scope :currently_online, -> { last_seen_within(15.minutes.ago) }
  # scope :active, -> { last_seen_within(30.days.ago) }
  # def active? = last_seen_at && (last_seen_at >= 30.days.ago)

  def can_authenticate?
    active?
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

  def trusted?
    %w[trusted admin superadmin owner].include?(access_level)
  end

  def admin?
    %w[admin superadmin owner].include?(access_level)
  end

  def superadmin?
    %w[superadmin owner].include?(access_level)
  end

  def owner?
    access_level == "owner"
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

  def full_name
    "#{first_name} #{last_name}"
  end

  def initals
    "#{first_name[0]}#{last_name[0]}"
  end

  def locked?
    locked_at.present?
  end

  def lock!
    update!(locked_at: Time.zone.now)

    # Invalidate all sessions
    # user_sessions.destroy_all
  end

  def unlock!
    update!(locked_at: nil)
  end

  # def last_login_at
  #   user_sessions.maximum(:created_at)
  # end

  # def last_seen_at
  #   user_sessions.maximum(:last_seen_at)
  # end

  private

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
