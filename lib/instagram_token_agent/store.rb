module InstagramTokenAgent
  # Handle interfacing with the database, updating and retrieving values
  class Store

    # Execute the given SQL and params
    def self.execute(sql, params = [])
      binds = params.map{|p| [nil, p]}
      ActiveRecord::Base.connection_pool.with_connection { |con| con.exec_query(sql, 'sql', binds) }
    end

    # Fetch the value row data and memoize
    # This doesn't check if the token has expired - we'll let the client sort
    # that out with Instagram.
    #
    # @return Proc
    def self.data
      row = execute('SELECT value, expires_at, created_at, success, response_body FROM tokens LIMIT 1').to_a[0]
      @data ||= OpenStruct.new({
        value: row['value'],
        success: row['success'],
        response_body: row['response_body'],
        expires: row['expires_at'],
        created: row['created_at']
      })
    end

    # Update the token value in the store
    # This assumes there's only ever a single row in the table
    # The initial insert is done via the setup task.
    def self.update(value, expires, success = true, response_body = nil)
      execute('UPDATE tokens SET value = $1, expires_at = $2, success = $3, response_body = $4', [value, expires, success, response_body])
    end

    #Accessors for the token data
    def self.value
      data.value
    end

    def self.expires
      data.expires
    end

    def self.success?
      data.success == true
    end

    def self.response_body
      data.response_body
    end

    def self.created
      data.created
    end
  end
end
