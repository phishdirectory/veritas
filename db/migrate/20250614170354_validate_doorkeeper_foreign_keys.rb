class ValidateDoorkeeperForeignKeys < ActiveRecord::Migration[8.0]
  def change
    validate_foreign_key :oauth_access_grants, :oauth_applications
    validate_foreign_key :oauth_access_tokens, :oauth_applications
    validate_foreign_key :oauth_access_grants, :users
    validate_foreign_key :oauth_access_tokens, :users
  end
end
