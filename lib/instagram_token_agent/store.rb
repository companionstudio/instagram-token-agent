module InstagramTokenAgent
  # Handle interfacing with the database, updating and retrieving values
  class Store

    # Execute the given SQL and params
    def self.execute(sql, params = [])
      ActiveRecord::Base.connection_pool.with_connection { |con| con.exec_query(sql, 'sql', params) }
    end

    # Fetch the value row data and memoize
    # This doesn't check if the token has expired - we'll let the client sort
    # that out with Instagram.
    #
    # @return Proc
    def self.data
      row = execute('SELECT value, expires_at, created_at FROM tokens LIMIT 1').to_a[0]
      @data ||= OpenStruct.new({
        value: row['value'],
        expires: row['expires_at'],
        created: row['created_at']
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
