# Handles connecting to the basic display API
module InstagramTokenAgent
  class Client
    include HTTParty
    attr_accessor :config

    def initialize(settings)
      @config = settings
    end

    # Does the provided signature match?
    def check_signature?(check_signature)
      check_signature == signature
    end

    def refresh
      response = get(config.refresh_endpoint, query: query_params(grant_type: 'ig_refresh_token'))
      Store.update(response['access_token'], Time.now + response['expires_in'])

      # If we're working with webhooks, schedule a job for the period [token_expiry_buffer] before the expiry.
      if config.refresh_webhook?
        scheduler = Temporize::Scheduler.new(config)
        scheduler.schedule((Time.now + response['expires_in'] - settings.token_expiry_buffer).utc.iso8601, signature)
      end
    end

    def username
      get(config.user_endpoint, query: query_params(fields: 'username'))['username']
    end

    def media
      get(config.media_endpoint, query: query_params(fields: ['caption', 'media_type', 'media_url']))
    end

    private

    def get(*opts)
      self.class.get(*opts)
    end

    def query_params(extra_params = {})
      {access_token: Store.value}.merge(extra_params)
    end

    # The HMAC'd secret + the current token value
    #
    # A valid signature is the HMAC'd webhook_secret + the existing token value
    # This is vulnerable to the token in the DB changing (perhaps via a manual update) after a job is scheduled
    # In that case, the job will fail, since the HMAC no longer matches the current token
    # This isn't bad, per se - it just means that whenever a token is updated, any old jobs must
    # be cleared, and a single new job scheduled.
    def signature
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), config.webhook_secret, InstagramTokenAgent::Store.value)
    end
  end
end
