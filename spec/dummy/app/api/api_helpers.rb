module ApiHelpers
  include IntrospectiveGrape::CamelSnake
  def warden
    env['warden']
  end

  def current_user
    warden.user || params[:api_key].present? && @user = User.find_by_authentication_token(params[:api_key])
  end

  def authenticate!
    unauthenticated! unless current_user 
  end

  # returns an 'unauthenticated' response
  def unauthenticated!(error_type = nil)
    respond_error!('unauthenticated', error_type, 401)
  end

  # returns a error response with given type, message_key and status
  def respond_error!(type, message_key, status = 500, other = {})
    e = {
      type: type,
      status: status
    }
    e['message_key'] = message_key if message_key
    e.merge!(other)
    error!({ error: e }, status)
  end

  private

  def safe_params(params)
    ActionController::Parameters.new(params)
  end
end
