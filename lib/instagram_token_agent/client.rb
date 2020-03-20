# Handles connecting to the basic display API
module InstagramTokenAgent
  class Client
    include HTTParty
    attr_accessor :config

    def initialize(settings)
      @config = settings
    end

    def refresh
      response = get(config.refresh_endpoint, query: query_params(grant_type: 'ig_refresh_token'))
      Store.update(response['access_token'], Time.now + response['expires_in'])
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
  end
end
