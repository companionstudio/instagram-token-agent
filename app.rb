require 'dotenv'
require 'bundler'

Dotenv.load
Bundler.require

require_relative 'lib/instagram_token_agent'

class App < Sinatra::Base
  register Sinatra::Namespace
  register Sinatra::CrossOrigin
  register InstagramTokenAgent::StorageExtension

  # Nicer debugging in dev mode
  configure :development do
    require 'pry'
    require "better_errors"
    use BetterErrors::Middleware
    BetterErrors.application_root = __dir__
  end

  configure do
    enable :cross_origin

    set :show_exceptions, false
    set :raise_errors, true

    set :allow_origin,      ENV['ALLOWED_DOMAINS'] || :any                      # Check for a whitelist of domains, otherwise allow anything
    set :allow_methods,     [:get, :options]                                    # Only allow GETs and OPTION requests
    set :allow_credentials, false                                               # We have no need of credentials!

    set :default_starting_token, 'replace_me'                                   # The 'Deploy to Heroku' button sets this environment value
    set :token_expiry_buffer, 2 * 24 * 60 * 60                                  # 2 days

    set :refresh_endpoint,  'https://graph.instagram.com/refresh_access_token'  # The endpoint to hit to extend the token
    set :user_endpoint,     'https://graph.instagram.com/me'                    # The endpoint to hit to fetch user profile
    set :media_endpoint,    'https://graph.instagram.com/me/media'              # The endpoint to hit to fetch the user's media

    enable :refresh_webhook if ENV['TEMPORIZE_URL']                             # Check if Temporize is configured
    set :webhook_secret, ENV['WEBHOOK_SECRET']                                  # The secret value used to sign external, incoming requests
  end

  before do
    # Make sure everything is set up before we try to do anything else
    ensure_configuration
  end

  # The 'hello world' page
  # @TODO: allow an environment var to turn this off, as it's never needed once in production
  get '/' do
    @client||= InstagramTokenAgent::Client.new(settings)

    haml(:index, layout: :'layouts/default')
  end

  # Show the setup page - mostly for dev
  get '/setup' do
    app_info
    haml(:setup, layout: :'layouts/default')
  end

  # The various token-returning routes
  namespace '/token' do

    # Enable CORS requests in this namespace
    cross_origin

    #Some clients will make an OPTIONS pre-flight request before doing CORS requests
    options do
      response.headers["Allow"] = settings.allow_methods
      response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"

      204
    end

    # Return the token itself
    # Formats:
    #  - .js
    #  - .json
    #  - plain text (default)
    #
    get ':format?' do
      # Tokens remain active even after refresh, so we can set the cache up close to FB's expiry
      cache_control :public, max_age: InstagramTokenAgent::Store.expires - Time.now - settings.token_expiry_buffer

      case params['format']
      when '.js'
        content_type 'application/javascript'
        erb :'javascript/snippet.js'
      when '.json'
        content_type 'application/json'
        json(token: InstagramTokenAgent::Store.value)
      else
        InstagramTokenAgent::Store.value
      end
    end
  end

  # This endpoint is used by the Temporize scheduling service to trigger a refresh externally
  if settings.refresh_webhook?
    post "/hooks/refresh/:signature" do


      client = InstagramTokenAgent::Client.new(app)
      if client.check_signature? params[:signature]
        client.refresh
      else
        halt 403
      end


    end
  end


  not_found do
    haml(:not_found, layout: :'layouts/default')
  end

  error do
    haml(:error, layout: :'layouts/default')
  end

  private

  # Show the setup screen if we're not yet ready to go
  def ensure_configuration
    halt haml(:setup, :'layouts/default') unless configured?
  end

  # Check that the configuration looks right to continue
  def configured?
    ENV['STARTING_TOKEN'] != settings.default_starting_token and !InstagramTokenAgent::Store.value.nil?
  end

  # Provide some info sourced from the app.json file
  def app_info
    InstagramTokenAgent::AppInfo.info
  end

end
