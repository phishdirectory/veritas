# app/constraints/admin_constraint.rb
# frozen_string_literal: true

class AdminConstraint
  def matches?(request)
    return false unless request.session[:user_id]

    user = User.find_by(id: request.session[:user_id])
    user&.admin?
  end

end
