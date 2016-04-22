class Dummy::Sessions < Grape::API

  resource :sessions do

    desc "create a user session" do
      detail "sign in a user"
    end
    params do
      requires :login,        type: String,  desc: "email address"
      requires :password,     type: String,  desc: "password"
      optional :token,        type: Boolean, desc: "set to true to generate and return Firebase secure token", default: false
    end
    post '/' do
      authorize User.new, :sessions?
      user = User.find_first_by_auth_conditions({email: params[:login]})
      if user && user.valid_password?(params[:password]) && user.valid_for_authentication?

        # commented out for now, User model is not yet confirmable
        #unauthenticated! DummyAPI::USER_NOT_CONFIRMED unless user.confirmed?

        token = nil
        if params[:token]
          payload = {
              uid: "#{user.id}", # uid must be a string
              email: user.email,
              avatar_url: user.avatar_url
          }
          user.authentication_token = SecureRandom.urlsafe_base64(nil, false)
          user.save
        end

        #user.ensure_authentication_token!
        env['warden'].set_user(user, scope: :user)
        present user, with: Dummy::Entities::User, token: token
      else
        unauthenticated! DummyAPI::BAD_LOGIN
      end
    end


    desc "delete a user session" do
      detail "sign out the current user" 
    end
    delete '/' do
      authorize User.new, :sessions?
      if u = User.find_by_authentication_token(params[:api_key])
        u.authentication_token = nil
        {status: u.save!}
      else
        {status: true } # the user is already logged out
      end
    end 

  end
end
