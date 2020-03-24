require './app'

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: :get
  end
end

if memcache_servers = ENV["MEMCACHIER_SERVERS"]
  use Rack::Cache,
    username: ENV['MEMCACHIER_USERNAME'],
    password: ENV['MEMCACHIER_PASSWORD'],
    verbose: true,
    metastore:   "memcached://#{memcache_servers}",
    entitystore: "memcached://#{memcache_servers}"
end

run App
