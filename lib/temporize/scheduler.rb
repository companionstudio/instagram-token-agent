# Interface with Temporize's cron add-on for Heroku,
# This takes care of scheduling the refresh job for the future when a new expiry is known.

module Temporize
  class Scheduler
    include HTTParty
    format :json
    attr_accessor :config

    def initialize(settings)
      @config = settings
    end

    #Queue a job to refresh the token at the specified time and date
    def queue_refresh(time, signature)
      
    end
  end
end
