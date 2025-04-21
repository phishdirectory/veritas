# frozen_string_literal: true

class CreateUserSeenAtHistories < ActiveRecord::Migration[8.0]
    def change
        create_table :user_seen_at_histories, &:timestamps
    end
end
