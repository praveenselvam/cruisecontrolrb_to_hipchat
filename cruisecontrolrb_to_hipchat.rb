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
  
  ENV["HIPCHAT_AUTH_TOKEN"] = "92e31b699b153614e36e54f6980aa9"
  ENV["HIPCHAT_ROOM_ID"] = "435492"

  MASTER_STATS = {}
  
  scheduler = Rufus::Scheduler.start_new
  
  scheduler.every("#{ENV["POLLING_INTERVAL"] || 10}s") do

    puts "Scheduler fired"
    
    status_hash = Pipeline.new(ENV["CC_URL"], ENV["CC_USERNAME"] || "", ENV["CC_PASSWORD"] || "", "Deploy_Indix_Site_Staging").fetch

    unless status_hash.empty?

      pipeline_name = status_hash["stage"]["pipeline"]["name"]
      result = status_hash["stage"]["result"]
      state = status_hash["stage"]["state"]

      old_status = MASTER_STATS[pipeline_name]

      old_result = old_status.nil? ? "" : old_status["stage"]["result"]

      if old_result != result

        message = "#{pipeline_name}: <a href='#{status_hash["website_link"]}'>#{result}</a>"

        color = result == "Passed" ? "green" : "red"
            
        puts "Posting: #{message}"
        Hipchat.new.hip_post message, color

      else

        puts "Status has not changed"

      end

      MASTER_STATS[pipeline_name] = status_hash

    end
  end
end

Sinatra::Application::run!