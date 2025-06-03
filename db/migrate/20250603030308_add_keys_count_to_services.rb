class AddKeysCountToServices < ActiveRecord::Migration[8.0]
  def up
    add_column :services, :keys_count, :integer, default: 0, null: false
    
    # Reset counter cache for existing records
    Service.find_each do |service|
      Service.reset_counters(service.id, :keys)
    end
  end
  
  def down
    remove_column :services, :keys_count
  end
end
