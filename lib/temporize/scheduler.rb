# Interface with Temporize's cron add-on for Heroku,
# This takes care of scheduling the refresh job for the future when a new expiry is known.

module Temporize
  class Scheduler
    include HTTParty
    format :json
    attr_accessor :config
    base_uri "#{ENV['TEMPORIZE_URL']}/v1"

    def initialize(settings)
      @config = settings
    end

    # Extract the auth details from the URL, since HTTParty doesn't like them by default
    def credentials
      if basic_auth = URI.parse(Temporize::Scheduler.base_uri).userinfo
        username, password = basic_auth.split(':')
        {:username => username, :password => password}
      end
    end

    # Wipe any existing jobs and create a new one
    def update!
      clear_all!

      client = InstagramTokenAgent::Client.new(config)
      queue_refresh(InstagramTokenAgent::Store.expires - config.token_expiry_buffer, client.signature)
    end

    #Queue a job to refresh the token at the specified time and date
    def queue_refresh(time, signature)
      hook_url = CGI::escape("#{config.app_url}/hooks/refresh/#{signature}")

      schedule = CGI::escape(if config.token_refresh_mode == :scheduled
        time.utc.iso8601
      else
        case config.token_refresh_frequency
        when :daily
          '0 0 * * ?'   # Midnight every day
        when :monthly
          '0 0 1 * ?'   # First day of each month
        else
          '0 0 * * ?'   # Every Sunday
        end
      end)
      Temporize::Scheduler.post("/events/#{schedule}/#{hook_url}", basic_auth: credentials).success?
    end

    # List all the jobs
    def jobs
      Temporize::Scheduler.get('/events', basic_auth: credentials)
    end

    # Get an individual job
    def job(id)
      Temporize::Scheduler.get("/events/#{id}", basic_auth: credentials)
    end

    # Find the next job
    def next_job
      job(jobs.first)
    end

    # Delete all upcoming jobs
    def clear_all!
      jobs.each do |id|
        Temporize::Scheduler.delete("/events/#{id}", basic_auth: credentials)
      end
    end
  end
end
