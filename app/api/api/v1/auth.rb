# frozen_string_literal: true

module Api
  module V1
    class Auth < Base
      resource :auth do
        desc "Authenticate a user"
        params do
          requires :credentials, type: String, desc: "Hashed credentials"
        end
        post do
          authenticate_service!

          credentials = dehash_credentials(params[:credentials])

          error!("Invalid credentials format", 400) unless credentials &&
                                                           credentials[:email] &&
                                                           credentials[:password]

          user = User.find_by(email: credentials[:email])

          if user&.can_authenticate? && user.authenticate(credentials[:password])
            {
              authenticated: true,
              pd_id: user.pd_id
            }
          else
            status 401
            { authenticated: false }
          end
        end
      end

    end
  end
end
