module InstagramTokenAgent
  # Handles storage and retrieval of the token value
  # This is currently assumed to back onto a minimal Postgres DB for use on Heroku,
  # but could be adapted to other stores if needed.
  module StorageExtension

    # When registered, pull the DB config info from:
    # - Environment DATABASE_URL. Used by Heroku
    # - config/database.yml. See README for options
    def self.registered(app)
      if ENV['DATABASE_URL']
        app.set(:database, ENV['DATABASE_URL'])
      elsif File.exist?("#{Dir.pwd}/config/database.yml")
        env_config = (YAML.load_file("#{Dir.pwd}/config/database.yml") || {})[app.environment.to_s]
        app.set(:database, env_config)
      end

      Store.config = app.database
    end
  end

  # Handle interfacing with the database, updating and retrieving values
  class Store
    require 'pg'

    # Store the config for future connections to use
    def self.config=(config)
      @config = config
    end

    # A shared connection object
    def self.connection
      @connection ||= PG.connect(@config)
    end

    # Execute the given SQL and params
    def self.execute(sql, params = [])
      connection.exec_params(sql, params)
    end

    # Fetch the value row data and memoize
    # This doesn't check if the token has expired - we'll let the client sort
    # that out with Instagram.
    #
    # @return Proc
    def self.data
      row = execute('SELECT value, expires_at, created_at FROM tokens LIMIT 1')
      @data ||= OpenStruct.new({
        value: row.getvalue(0,0),
        expires: DateTime.parse(row.getvalue(0,1)).to_time,
        created: DateTime.parse(row.getvalue(0,2)).to_time
      })
    end

    # Update the token value in the store
    # This assumes there's only ever a single row in the table
    # The initial insert is done via the setup task.
    def self.update(value, expires)
      execute('UPDATE tokens SET value = $1, expires_at = $2', [value, expires])
    end

    #Accessors for the token data
    def self.value
      data.value
    end

    def self.expires
      data.expires
    end

    def self.created
      data.created
    end
  end
end
