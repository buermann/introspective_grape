module ApiHelpers
  def current_user
    params[:api_key].present? && @user = User.find_by_authentication_token(params[:api_key])
    # for testing in situ
    #@user = User.find_or_create_by(email: 'test@test.com', superuser: true, authentication_token: '1234567890', first_name: "First", last_name: "Last")
  end

  def authenticate!
    unauthenticated! unless login_request? || current_user
  end

  def login_request?
    self.method_name.start_with?('POST') && self.namespace == '/sessions'
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
