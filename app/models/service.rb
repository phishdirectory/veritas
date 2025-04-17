# app/models/service.rb
# == Schema Information
#
# Table name: services
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  status     :string           default("active"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_services_on_name  (name) UNIQUE
#
class Service < ApplicationRecord
  include AASM

  has_many :keys, class_name: 'Service::Key', dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :status, presence: true

  # State machine for service status
  aasm column: :status do
    state :active, initial: true
    state :suspended
    state :decommissioned

    event :suspend do
      transitions from: :active, to: :suspended
    end

    event :reactivate do
      transitions from: :suspended, to: :active
    end

    event :decommission do
      transitions from: [:active, :suspended], to: :decommissioned
    end
  end

  # Get the current active key for this service
  def current_key
    keys.active.order(created_at: :desc).first
  end

  # Generate a new key for this service
  def generate_key(notes = nil)
    keys.create(notes: notes)
  end

  # Authenticate using an API key
  def self.authenticate(api_key)
    key = Service::Key.find_by(api_key: api_key)
    return nil unless key&.may_use?
    key.service if key.service.active?
  end

  def self.create_with_key(name, notes = nil)
    service = nil

    transaction do
      service = create(name: name)

      if service.persisted?
        key = service.generate_key(notes || "Initial key created via console")

        if key.persisted?
          puts "Service created successfully:"
          puts "  Name:      #{service.name}"
          puts "  Status:    #{service.status}"
          puts "  API Key:   #{key.api_key}"
          puts "  Hash Key:  #{key.hash_key}"
          puts "  Key ID:    #{key.id}"
          puts "  Notes:     #{key.notes}"
        else
          puts "Error creating key: #{key.errors.full_messages.join(', ')}"
          raise ActiveRecord::Rollback
        end
      else
        puts "Error creating service: #{service.errors.full_messages.join(', ')}"
      end
    end

    service
  end
end
