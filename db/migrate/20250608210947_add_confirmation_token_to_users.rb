class AddConfirmationTokenToUsers < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmation_sent_at, :datetime
    add_index :users, :confirmation_token, unique: true, algorithm: :concurrently
  end
end
