require 'dotenv'
require 'bundler'

Dotenv.load
Bundler.require

require_relative 'lib/instagram_token_agent'

class App < Sinatra::Base
  register Sinatra::ActiveRecordExtension
  register Sinatra::CrossOrigin

  # Nicer debugging in dev mode
  configure :development do
    require 'pry'
    require "better_errors"
    use BetterErrors::Middleware
    BetterErrors.application_root = __dir__
  end

  # -------------------------------------------------
  # Overall configuration - done here rather than yml files to reduce dependencies
  # -------------------------------------------------
  configure do
    set :app_name, ENV['APP_NAME']                                                # The app needs to know its own name/url.
    set :app_url, ENV['APP_URL'] || "https://#{settings.app_name}.herokuapp.com"

    enable :cross_origin
    disable :show_exceptions
    enable :raise_errors

    set :help_pages,        !(ENV['HIDE_HELP_PAGES']) || false                    # Whether to display the welcome pages or not
    set :allow_origin,      ENV['ALLOWED_DOMAINS'] ? ENV['ALLOWED_DOMAINS'].split(' ').map{|d| "https://#{d}"} : settings.app_url # Check for a whitelist of domains, otherwise allow the herokapp domain
    set :allow_methods,     [:get, :options]                                      # Only allow GETs and OPTION requests
    set :allow_credentials, false                                                 # We have no need of credentials!

    set :default_starting_token, 'copy_token_here'                                # The 'Deploy to Heroku' button sets this environment value
    set :js_constant_name, ENV['JS_CONSTANT_NAME'] ||'InstagramToken'             # The name of the constant used in the JS snippet

    set :token_expiry_buffer, 2 * 24 * 60 * 60                                    # 2 days before expiry

    set :refresh_endpoint,  'https://graph.instagram.com/refresh_access_token'    # The endpoint to hit to extend the token
    set :user_endpoint,     'https://graph.instagram.com/me'                      # The endpoint to hit to fetch user profile
    set :media_endpoint,    'https://graph.instagram.com/me/media'                # The endpoint to hit to fetch the user's media
  end

  # Make sure everything is set up before we try to do anything else
  before do
    ensure_configuration!
  end

  # Switch for the help pages
  unless settings.help_pages?
    ['/', '/status', '/setup'].each do |help_page|
      before help_page do
        halt 204
      end
    end
  end

  # -------------------------------------------------
  # The 'hello world' pages
  # @TODO: allow an environment var to turn this off, as it's never needed once in production
  # -------------------------------------------------

  # The home page
  get '/' do
    haml(:index, layout: :'layouts/default')
  end

  # Requested by the index page, this checks the status of the
  # refresh task and talks to Instagram to ensure everything's set up.
  get '/status' do
    @client ||= InstagramTokenAgent::Client.new(settings)
    check_refresh_job
    haml(:status, layout: nil)
  end

  # Show the setup page - mostly for dev, this is shown automatically in production
  get '/setup' do
    app_info
    haml(:setup, layout: :'layouts/default')
  end

  get '/instafeed' do
    haml(:instafeed, layout: :'layouts/default')
  end

  # Allow a manual refresh, but only if the previous attempt failed
  post '/refresh' do
    if InstagramTokenAgent::Store.success?
      halt 204
    else
      client = InstagramTokenAgent::Client.new(settings)
      client.refresh
      redirect '/setup'
    end
  end

  # -------------------------------------------------
  # The Token API
  # This is a good candidate for a Sinatra namespace, but sinatra-contrib needs updating
  # -------------------------------------------------

  #Some clients will make an OPTIONS pre-flight request before doing CORS requests
  options '/token' do
    cross_origin

    response.headers["Allow"] = settings.allow_methods
    response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"

    204 #'No Content'
  end

  # Return the token itself
  # Formats:
  #  - .js
  #  - .json
  #  - plain text (default)
  #
  get '/token:format?' do
    # Tokens remain active even after refresh, so we can set the cache up close to FB's expiry
    cache_control :public, max_age: InstagramTokenAgent::Store.expires - Time.now - settings.token_expiry_buffer

    cross_origin

    response_body = case params['format']
    when '.js'
      content_type 'application/javascript'

      @js_constant_name = params[:const] || settings.js_constant_name;

      erb(:'javascript/snippet.js')

    when '.json'
      content_type 'application/json'
      json(token: InstagramTokenAgent::Store.value)
    else
      InstagramTokenAgent::Store.value
    end

    etag Digest::SHA1.hexdigest(response_body + (response.headers['Access-Control-Allow-Origin'] || '*'))

    response_body
  end

  # -------------------------------------------------
  # Error pages
  # -------------------------------------------------

  not_found do
    haml(:not_found, layout: :'layouts/default')
  end

  error do
    haml(:error, layout: :'layouts/default')
  end

  helpers do

    # Provide some info sourced from the app.json file
    def app_info
      @app_info ||= InstagramTokenAgent::AppInfo.info
    end

    # Check that the configuration looks right to continue
    def configured?
      return false unless check_allowed_domains
      return false unless check_starting_token
      true
    end

    # Show the setup screen if we're not yet ready to go.
    def ensure_configuration!
      halt haml(:setup, layout: :'layouts/default') unless configured?
    end

    def check_allowed_domains
      ENV['ALLOWED_DOMAINS'].present? and !ENV['ALLOWED_DOMAINS'].match(/\*([^\.]|$)/) # Disallow including * in the allow list
    end

    def check_starting_token
      ENV['STARTING_TOKEN'] != settings.default_starting_token
    end

    def check_token_status
      InstagramTokenAgent::Store.success? and InstagramTokenAgent::Store.value.present?
    end

    def latest_instagram_response
      JSON.pretty_generate(JSON.parse(InstagramTokenAgent::Store.response_body))
    end
  end
end
