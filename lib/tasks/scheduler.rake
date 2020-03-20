desc "Refresh the token value with the Instagram API"
task :refresh_token=> :environment do
  client = InstagramTokenAgent::Client.new(app)
  client.refresh
end
