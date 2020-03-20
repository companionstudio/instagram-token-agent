require './app'

Dir.glob('lib/tasks/*.rake').each { |r| load r}

task :environment do
  Sinatra::Application.environment = ENV['RACK_ENV']

  def app
    App
  end
end
