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

    # Fetch a fresh token from the instagram API
    #
    # @return Boolean indicating success or failure
    def refresh
      response = get(
        config.refresh_endpoint,
        query: query_params(grant_type: 'ig_refresh_token'),
        headers: {"User-Agent" => "Instagram Token Agent"}
      )

      if response.success?

        Store.update(response['access_token'], Time.now + response['expires_in'], true, nil)

        true
      else

        Store.update(ENV['STARTING_TOKEN'], Time.now, false, response.body)

        false
      end
    end

    def username
      get(config.user_endpoint, query: query_params(fields: 'username'))['username']
    end

    def media
      response = get(config.media_endpoint, query: query_params(fields: 'media_url'))
      # Ew. This is gross
      if response.success?
        JSON.parse(response.body)['data'][0]['media_url']
      else
        nil
      end
    end

    # The HMAC'd secret + initial token value
    # It would be better to hash the current token value, but this won't work with recurring jobs, since
    # the value needs to stay consistent.
    def signature
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), config.webhook_secret, ENV['STARTING_TOKEN'])
    end

    private

    def get(*opts)
      self.class.get(*opts)
    end

    def query_params(extra_params = {})
      {access_token: Store.value}.merge(extra_params)
    end

  end
end
