# frozen_string_literal: true

module ServiceMappings
  def self.service_name_to_id(service_name)
    service_name = service_name.downcase

    case service_name
    when "internal"
      1
    when "api"
      2
    when "momento"
      3
    else
      nil
    end
  end

  def self.service_id_to_name(service_id)
    case service_id
    when 1
      "Internal"
    when 2
      "API"
    when 3
      "Momento"
    else
      nil
    end
  end
end
