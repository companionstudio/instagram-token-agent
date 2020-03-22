require_relative 'instagram_token_agent/store'
require_relative 'instagram_token_agent/client'
require_relative 'temporize/scheduler'

module InstagramTokenAgent
  module AppInfo
    def self.info
      if File.exist?("#{Dir.pwd}/app.json")
        file = File.read("#{Dir.pwd}/app.json")
        data = JSON.parse(file)
      else
        {}
      end
    end
  end
end
