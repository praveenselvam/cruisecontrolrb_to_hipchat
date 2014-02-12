require "sinatra"
require "sinatra/base"
require "./cruisecontrolrb"
require "./pipeline"
require "./hipchat"
require 'rufus-scheduler'

class CruisecontrolrbToHipchat < Sinatra::Base
    
  attr_accessor :status
  attr_accessor :activity

  ENV["CC_URL"] = "http://ci-server.indix.tv:8080/"
  ENV["CC_USERNAME"] = "praveen"
  ENV["CC_PASSWORD"] = "lisyYAcx7mJj3"
  
  ENV["HIPCHAT_AUTH_TOKEN"] = "eUl5nkzUkB3GqnLhisuN1KpmJTsJNhwYqEHMDFpd"
  ENV["HIPCHAT_ROOM_ID"] = "435492"
  
  scheduler = Rufus::Scheduler.start_new

  puts "Starting scheduler..."
  
  scheduler.every("#{ENV["POLLING_INTERVAL"] || 10}s") do

    puts "Scheduler fired"
    
    status_hash = Pipeline.new(ENV["CC_URL"], ENV["CC_USERNAME"] || "", ENV["CC_PASSWORD"] || "", "Deploy_Indix_Site_Staging").fetch

    unless status_hash.empty?

      pipeline_name = status_hash["stage"]["pipeline"]["name"]
      result = status_hash["stage"]["result"]
      state = status_hash["stage"]["state"]

      message = "#{pipeline_name}: #{state} #{result}"

      color = status_hash[:lastBuildStatus] == "Success" ? "green" : "red"
          
      puts "Posting: #{message}"
      Hipchat.new.hip_post message, color

    end
  end
end

Sinatra::Application::run!