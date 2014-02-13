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
  ENV["HIPCHAT_FROM"] = "Auto-Warden"

  ROOMS = {
    "Test AAA" => "437773",
    "Test Analytics" => "439156",
    "Test App" => "435492",

    "EE3-Production-Bug-Fixes" => "433748",
    "Product Score" => "433742",
    "Analytics" => "225998",
    "App" => "439155"
  } 

  MASTER_STATS = {}

  COMMUNICATION_CONFIG = [{
    "name" => "Business",
    "rooms" => [ROOMS["Test AAA"]]
  },{
    "name" => "FT",
    "rooms" => [ROOMS["Test AAA"]]
  },{
    "name" => "Service-Analytics",
    "rooms" => [ROOMS["Test AAA"]]
  },{
    "name" => "Cosmos-Data",
    "rooms" => [ROOMS["Test AAA"]]
  },{
    "name" => "SavedList-Export-Staging",
    "rooms" => [ROOMS["Test AAA"]]
  },{
    "name" => "CustomList_Verify_And_Notify",
    "rooms" => [ROOMS["Test AAA"]]
  },{
    "name" => "BG-Deploy-Staging",
    "rooms" => [ROOMS["Test AAA"]]
  },{
    "name" => "SavedList-Export-Prod",
    "rooms" => [ROOMS["Test AAA"]]
  },{
    "name" => "Analytics-Refresh-Production",
    "rooms" => [ROOMS["Test AAA"]]
  },{
    "name" => "BG-Data-Refresh-Production",
    "rooms" => [ROOMS["Test AAA"]]
  },{
    "name" => "BG-Deploy-Production",
    "rooms" => [ROOMS["Test AAA"]]
  },{
    "name" => "Production-Mongo-Backup",
    "rooms" => [ROOMS["Test AAA"]]
  },{
    "name" => "Staging-Mongo-Backup",
    "rooms" => [ROOMS["Test AAA"]]
  },{
    "name" => "Services",
    "rooms" => [ROOMS["Test AAA"]]
  },{
    "name" => "Cosmos",
    "rooms" => [ROOMS["Test AAA"]]
  },{
    "name" => "Oogway",
    "rooms" => [ROOMS["Test AAA"]]
  },{
    "name" => "Analytics-Refresh-FT",
    "rooms" => [ROOMS["Test AAA"]]
  },{
    "name" => "Promotions",
    "rooms" => [ROOMS["Test App"]]
  },{
    "name" => "Deploy-Promotions-Staging",
    "rooms" => [ROOMS["Test App"]]
  },{
    "name" => "Deploy-API-Signup",
    "rooms" => [ROOMS["Test App"]]
  },{
    "name" => "Deploy-Promotions-Production",
    "rooms" => [ROOMS["Test App"]]
  },{
    "name" => "Deploy-API-Signup-Production",
    "rooms" => [ROOMS["Test App"]]
  },{
    "name" => "Cosmos-App",
    "rooms" => [ROOMS["Test App"]]
  },{
    "name" => "Jobs-Analytics",
    "rooms" => [ROOMS["Test Analytics"]]
  },{
    "name" => "Apeiron",
    "rooms" => [ROOMS["Test Analytics"]]
  },{
    "name" => "BG-Data-Refresh-Staging",
    "rooms" => [ROOMS["Test Analytics"]]
  },{
    "name" => "Analytics-Production-Backup",
    "rooms" => [ROOMS["Test Analytics"]]
  },{
    "name" => "Deploy-Pi",
    "rooms" => [ROOMS["Product Score"]]
  }]

  COMMUNICATION_CONFIG.each do |pipeline|

    scheduler = Rufus::Scheduler.start_new

    puts "New Scheduler created"

    scheduler.every("#{ENV["POLLING_INTERVAL"] || 30}s") do

      puts "Scheduler fired"

      puts "Checking #{pipeline["name"]}"

      status_hash = Pipeline.new(ENV["CC_URL"], ENV["CC_USERNAME"] || "", ENV["CC_PASSWORD"] || "", "#{pipeline["name"]}").fetch

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

          pipeline["rooms"].each do |room_id|
            puts "Posting to #{room_id}"
            # Hipchat.new.hip_post room_id, message, color
          end

        else

          puts "#{pipeline_name}: Status has not changed"

        end

        MASTER_STATS[pipeline_name] = status_hash

      end
    end
    
  end

  get "/" do
    "ROAR!!!"
  end
end

get "/" do
  "ROAR!!!"
end

# Sinatra::Application::run!