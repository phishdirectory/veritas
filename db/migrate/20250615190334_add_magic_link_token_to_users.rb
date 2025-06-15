class AddMagicLinkTokenToUsers < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_column :users, :magic_link_token, :string
    add_index :users, :magic_link_token, unique: true, algorithm: :concurrently
    add_column :users, :magic_link_expires_at, :datetime
    add_column :users, :magic_link_sent_at, :datetime
    add_column :users, :magic_link_used_at, :datetime
  end
end
