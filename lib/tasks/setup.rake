desc "Perform initial setup of the database"
task :setup => :environment do

  # Create the table in the DB. This is assumed to be Postgres.
  InstagramTokenAgent::Store.execute <<-SQL
    CREATE TABLE IF NOT EXISTS tokens (
      value         varchar(256) NOT NULL,
      created_at    timestamp DEFAULT current_timestamp,
      expires_at    timestamp
    )
  SQL

  # Seed the initial row in the table with the token from the environment.
  if ENV['STARTING_TOKEN'] and ENV['STARTING_TOKEN'] != app.default_starting_token
    InstagramTokenAgent::Store.execute 'INSERT INTO tokens (value, expires_at) VALUES ($1, $2)', [ENV['STARTING_TOKEN'], Time.now - 1]

    # Run an initial refresh to populate expiries etc.
    client = InstagramTokenAgent::Client.new(app)
    client.refresh
  end

end
