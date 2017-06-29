require_relative "active_lms"

# https://github.com/atomicjolt/omniauth-canvas#state
OmniAuth.config.before_request_phase do |env|
  request = Rack::Request.new(env)
  state = "#{SecureRandom.hex(24)}#{DateTime.now.to_i}"
  OauthState.create!(state: state, payload: request.params.to_json)
  env["omniauth.strategy"].options[:authorize_params].state = state

  # By default omniauth will store all params in the session. The code above
  # stores the values in the database so we remove the values from the session
  # since the amount of data in the original params object will overflow the
  # allowed cookie size
  env["rack.session"].delete("omniauth.params")
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :canvas, ActiveLMS.configuration.providers[:canvas].client_id,
    ActiveLMS.configuration.providers[:canvas].client_secret, setup: true
  provider :developer unless Rails.env.production?
  provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_SECRET"],
    scope: 'userinfo.email, calendar', prompt: 'consent', select_account: true, access_type: 'offline'
  provider :lti, :oauth_credentials => { ENV["LTI_CONSUMER_KEY"] => ENV["LTI_CONSUMER_SECRET"] }
  provider :kerberos, uid_field: :username, fields: [ :username, :password ]
end
