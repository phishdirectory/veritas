# frozen_string_literal: true

class AdminConstraint
  def matches?(request)
    return false unless request.session[:session_id]

    session = Session.find_by(id: request.session[:session_id])
    return false unless session&.active?

    user = session.user
    return false unless user&.can_authenticate?

    user.admin_or_higher?
  end
end