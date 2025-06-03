class AddUserData < ActiveRecord::Migration[8.0]
  def change
    # todo: implement signup_service
    add_column :users, :signup_service, :integer, null: false
    # todo: implement services_used
    add_column :users, :services_used, :integer, array: true, default: []
  end
end
