class AddUsernameToUsers < ActiveRecord::Migration[8.0]
  def up
    safety_assured do
      add_column :users, :username, :string, null: true


    # Backfill usernames using update_all and SQL string functions
    # This example assumes all emails contain '@'
    execute <<-SQL.squish
      UPDATE users
      SET username = SUBSTRING(email FROM 1 FOR POSITION('@' IN email) - 1)
      WHERE email IS NOT NULL AND username IS NULL
    SQL

    change_column_null :users, :username, false
    end
  end

  def down
    remove_column :users, :username
  end
end
