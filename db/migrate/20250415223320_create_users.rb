class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|

      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :pd_id, null: false


      t.string :email, null: false
      t.boolean :email_verified, default: false
      t.datetime :email_verified_at

      t.string :password_digest, null: false

      t.integer :access_level, default: 0, null: false
      t.string :status, null: false, default: 'active'
      t.datetime :locked_at,

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :pd_id, unique: true

  end
end
