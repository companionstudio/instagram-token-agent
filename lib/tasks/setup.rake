desc "Perform initial setup of the database"
task :setup => :environment do

  Rake::Task["migrate"].invoke

  # Seed the initial row in the table with the token from the environment.
  if ENV['STARTING_TOKEN'] and ENV['STARTING_TOKEN'] != app.default_starting_token
    InstagramTokenAgent::Store.execute 'INSERT INTO tokens (value, expires_at, success) VALUES ($1, $2, $3)', [ENV['STARTING_TOKEN'], Time.now - 1, true]

    # Run an initial refresh to populate expiries etc.
    client = InstagramTokenAgent::Client.new(app)
    client.refresh
  end

end

desc "Create the DB tables"
task :migrate => :environment do
  # Create the table in the DB. This is assumed to be Postgres.
  InstagramTokenAgent::Store.execute <<-SQL
    CREATE TABLE IF NOT EXISTS tokens (
      value           varchar(256),
      created_at      timestamp DEFAULT current_timestamp,
      expires_at      timestamp,
      success         boolean,
      response_body   text
    )
  SQL
end


desc "Reset the database"
task :reset => :environment do
  InstagramTokenAgent::Store.execute <<-SQL
    DROP TABLE IF EXISTS tokens
  SQL

  Rake::Task["migrate"].invoke

end
