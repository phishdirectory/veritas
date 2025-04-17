class CreateUserSeenAtHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :user_seen_at_histories do |t|
      t.timestamps
    end
  end
end
