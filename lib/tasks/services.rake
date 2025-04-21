# frozen_string_literal: true

# lib/tasks/services.rake
namespace :services do
    desc 'Create a new service'
    task :create, [:name] => :environment do |_t, args|
        name = args[:name]

        if name.blank?
            puts 'Error: Service name is required'
            puts 'Usage: rails services:create[service_name]'
            next
        end

        service = Service.new(name: name)

        if service.save
            key = service.generate_key('Initial key created via rake task')
            puts 'Service created successfully:'
            puts "  Name:      #{service.name}"
            puts "  Status:    #{service.status}"
            puts "  API Key:   #{key.api_key}"
            puts "  Hash Key:  #{key.hash_key}"
            puts "  Key ID:    #{key.id}"
            puts "  Notes:     #{key.notes}"
        else
            puts "Error creating service: #{service.errors.full_messages.join(', ')}"
        end
    end

    desc 'Generate a new key for a service'
    task :generate_key, %i[service_name notes] => :environment do |_t, args|
        name = args[:service_name]
        notes = args[:notes]

        if name.blank?
            puts 'Error: Service name is required'
            puts 'Usage: rails services:generate_key[service_name,optional_notes]'
            next
        end

        service = Service.find_by(name: name)

        unless service
            puts "Error: Service '#{name}' not found"
            next
        end

        key = service.generate_key(notes)

        if key.persisted?
            puts 'Key generated successfully:'
            puts "  Service:   #{service.name}"
            puts "  API Key:   #{key.api_key}"
            puts "  Hash Key:  #{key.hash_key}"
            puts "  Key ID:    #{key.id}"
            puts "  Status:    #{key.status}"
            puts "  Notes:     #{key.notes}" if key.notes.present?
        else
            puts "Error generating key: #{key.errors.full_messages.join(', ')}"
        end
    end

    desc "Rotate a service's active key"
    task :rotate_key, %i[service_name notes] => :environment do |_t, args|
        name = args[:service_name]
        notes = args[:notes]

        if name.blank?
            puts 'Error: Service name is required'
            puts 'Usage: rails services:rotate_key[service_name,optional_notes]'
            next
        end

        service = Service.find_by(name: name)

        unless service
            puts "Error: Service '#{name}' not found"
            next
        end

        current_key = service.current_key

        unless current_key
            puts "No active key found for service '#{name}', generating a new one..."
            key = service.generate_key(notes)

            if key.persisted?
                puts 'Key generated successfully:'
                puts "  Service:   #{service.name}"
                puts "  API Key:   #{key.api_key}"
                puts "  Hash Key:  #{key.hash_key}"
                puts "  Key ID:    #{key.id}"
                puts "  Status:    #{key.status}"
                puts "  Notes:     #{key.notes}" if key.notes.present?
            else
                puts "Error generating key: #{key.errors.full_messages.join(', ')}"
            end

            next
        end

        new_key = current_key.rotate!(notes)

        if new_key.persisted?
            puts 'Key rotated successfully:'
            puts "  Service:       #{service.name}"
            puts "  Old Key ID:    #{current_key.id} (now #{current_key.status})"
            puts "  New API Key:   #{new_key.api_key}"
            puts "  New Hash Key:  #{new_key.hash_key}"
            puts "  New Key ID:    #{new_key.id}"
            puts "  Status:        #{new_key.status}"
            puts "  Notes:         #{new_key.notes}" if new_key.notes.present?
        else
            puts "Error rotating key: #{new_key.errors.full_messages.join(', ')}"
        end
    end

    desc 'Revoke a specific key'
    task :revoke_key, %i[service_name key_id notes] => :environment do |_t, args|
        name = args[:service_name]
        key_id = args[:key_id]
        notes = args[:notes]

        if name.blank? || key_id.blank?
            puts 'Error: Service name and key ID are required'
            puts 'Usage: rails services:revoke_key[service_name,key_id,optional_notes]'
            next
        end

        service = Service.find_by(name: name)

        unless service
            puts "Error: Service '#{name}' not found"
            next
        end

        key = service.keys.find_by(id: key_id)

        unless key
            puts "Error: Key ID '#{key_id}' not found for service '#{name}'"
            next
        end

        if key.revoked?
            puts 'Key is already revoked'
            next
        end

        key.notes = "#{key.notes}\n#{notes}".strip if notes.present?
        key.revoke!

        puts 'Key revoked successfully:'
        puts "  Service:   #{service.name}"
        puts "  Key ID:    #{key.id}"
        puts "  Status:    #{key.status}"
        puts "  Notes:     #{key.notes}" if key.notes.present?
    end

    desc 'List all services and their keys'
    task list: :environment do
        services = Service.order(:name)

        if services.empty?
            puts 'No services found'
        else
            puts 'Services:'
            services.each do |service|
                puts "  #{service.name} (#{service.status})"
                puts '  Keys:'

                keys = service.keys.order(created_at: :desc)

                if keys.empty?
                    puts '    No keys found'
                else
                    keys.each do |key|
                        puts "    ID: #{key.id} (#{key.status})"
                        puts "      API Key:   #{key.api_key}"
                        puts "      Hash Key:  #{key.hash_key}"
                        puts "      Created:   #{key.created_at}"
                        puts "      Notes:     #{key.notes}" if key.notes.present?
                        puts ''
                    end
                end

                puts ''
            end
        end
    end
end
