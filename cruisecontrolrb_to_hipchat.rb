require "sinatra"
require "sinatra/base"
require "./cruisecontrolrb"
require "./pipeline"
require "./hipchat"
require "./git_update"
require 'rufus-scheduler'

# set :port, 9494

ROOMS = {
  "Test AAA" => "437773",
  "Test Analytics" => "439156",
  "Test App" => "435492",
  "Git Integ Test" => "439499",

  "EE3-Production-Bug-Fixes" => "433748",
  "Product Score" => "433742",
  "Analytics" => "225998",
  "App" => "439155",
  "UI" => "225942",
  "Apeiron - Migration - Dev" => "457088"
} 

COMMUNICATION_TO_CONFIGURE = [{
  "pipeline_name" => "Service-Analytics",
  "rooms" => [ROOMS["Test AAA"]]
},{
  "pipeline_name" => "BG-Deploy-Staging",
  "rooms" => [ROOMS["Test AAA"]]
},{
  "pipeline_name" => "Analytics-Refresh-Production",
  "rooms" => [ROOMS["Test AAA"]]
},{
  "pipeline_name" => "BG-Data-Refresh-Production",
  "rooms" => [ROOMS["Test AAA"]]
},{
  "pipeline_name" => "BG-Deploy-Production",
  "rooms" => [ROOMS["Test AAA"]]
},{
  "pipeline_name" => "Services",
  "rooms" => [ROOMS["Test AAA"]]
},{
  "pipeline_name" => "Analytics-Refresh-FT",
  "rooms" => [ROOMS["Test AAA"]]
},{
  "pipeline_name" => "Deploy-Promotions-Production",
  "rooms" => [ROOMS["Test App"]]
},{
  "pipeline_name" => "BG-Data-Refresh-Staging",
  "rooms" => [ROOMS["Test Analytics"]]
}]

COMMUNICATION_CONFIG = [{
  "pipeline_name" => "Business",
  "stage_name" => "dev",
  "rooms" => [ROOMS["EE3-Production-Bug-Fixes"]]
},{
  "pipeline_name" => "FT",
  "stage_name" => "api-ft",
  "rooms" => [ROOMS["EE3-Production-Bug-Fixes"]]
},{
  "pipeline_name" => "Cosmos-Data",
  "stage_name" => "push-data",
  "rooms" => [ROOMS["EE3-Production-Bug-Fixes"]]
},{
  "pipeline_name" => "SavedList-Export-Staging",
  "stage_name" => "export",
  "rooms" => [ROOMS["EE3-Production-Bug-Fixes"]]
},{
  "pipeline_name" => "CustomList_Verify_And_Notify",
  "stage_name" => "run",
  "rooms" => [ROOMS["EE3-Production-Bug-Fixes"]]
},{
  "pipeline_name" => "SavedList-Export-Prod",
  "stage_name" => "export",
  "rooms" => [ROOMS["EE3-Production-Bug-Fixes"]]
},{
  "pipeline_name" => "Production-Mongo-Backup",
  "stage_name" => "backup-mongo",
  "rooms" => [ROOMS["EE3-Production-Bug-Fixes"]]
},{
  "pipeline_name" => "Staging-Mongo-Backup",
  "stage_name" => "backup-mongo",
  "rooms" => [ROOMS["EE3-Production-Bug-Fixes"]]
},{
  "pipeline_name" => "Cosmos",
  "stage_name" => "dev",
  "rooms" => [ROOMS["EE3-Production-Bug-Fixes"]]
},{
  "pipeline_name" => "Oogway",
  "stage_name" => "Test",
  "rooms" => [ROOMS["EE3-Production-Bug-Fixes"]]
},{
  "pipeline_name" => "Promotions",
  "stage_name" => "push-data",
  "rooms" => [ROOMS["App"]]
},{
  "pipeline_name" => "Deploy-Promotions-Staging",
  "stage_name" => "deploy-all-promotions",
  "rooms" => [ROOMS["App"]]
},{
  "pipeline_name" => "Deploy-API-Signup",
  "stage_name" => "deploy",
  "rooms" => [ROOMS["App"]]
},{
  "pipeline_name" => "Deploy-API-Signup-Production",
  "stage_name" => "deploy",
  "rooms" => [ROOMS["App"]]
},{
  "pipeline_name" => "Cosmos-App",
  "stage_name" => "deploy-all",
  "rooms" => [ROOMS["App"]]
},{
  "pipeline_name" => "Jobs-Analytics",
  "stage_name" => "Test",
  "rooms" => [ROOMS["Analytics"]]
},{
  "pipeline_name" => "Apeiron",
  "stage_name" => "Test",
  "rooms" => [ROOMS["Analytics"]]
},{
  "pipeline_name" => "Analytics-Production-Backup",
  "stage_name" => "backup-solr",
  "rooms" => [ROOMS["Analytics"]]
},{
  "pipeline_name" => "Deploy-Pi",
  "stage_name" => "deploy-pi",
  "rooms" => [ROOMS["Product Score"]]
}]

class CruisecontrolrbToHipchat < Sinatra::Base
    
  attr_accessor :status
  attr_accessor :activity

  ENV["CC_URL"] = "http://ci-server.indix.tv:8080/"
  ENV["CC_USERNAME"] = "praveen"
  ENV["CC_PASSWORD"] = "lisyYAcx7mJj3"
  
  ENV["HIPCHAT_AUTH_TOKEN"] = "92e31b699b153614e36e54f6980aa9"
  ENV["HIPCHAT_FROM"] = "Auto-Warden"

  MASTER_STATS = {}

  COMMUNICATION_CONFIG.each do |pipeline|

    scheduler = Rufus::Scheduler.start_new

    puts "New Scheduler created for #{pipeline["pipeline_name"]}"

    scheduler.every("#{ENV["POLLING_INTERVAL"] || 1}m") do

      puts "Checking #{pipeline["pipeline_name"]} - #{pipeline["stage_name"]}"

      status_hash = Pipeline.new(ENV["CC_URL"], ENV["CC_USERNAME"] || "", ENV["CC_PASSWORD"] || "", "#{pipeline["pipeline_name"]}", "#{pipeline["stage_name"]}").fetch

      unless status_hash.empty?

        pipeline_name = status_hash["stage"]["pipeline"]["name"]
        result = status_hash["stage"]["result"]
        state = status_hash["stage"]["state"]

        old_status = MASTER_STATS[pipeline_name]
        # Don't post the very first time.
        first_status = old_status.nil? ? true : false
        old_result = old_status.nil? ? "" : old_status["stage"]["result"]

        if old_result != result
          if first_status == true
            puts "#{pipeline_name}: #{result} [Not posting first time status]"
          else
            message = "#{pipeline_name}: <a href='#{status_hash["website_link"]}'>#{result}</a>"
            color = result == "Passed" ? "green" : "red"
            pipeline["rooms"].each do |room_id|
              puts "Posting to #{room_id} - #{message}"
              Hipchat.new.hip_post room_id, message, ENV["HIPCHAT_FROM"], color, 1
            end
          end
        else
          puts "#{pipeline_name}: Status has not changed"
        end

        MASTER_STATS[pipeline_name] = status_hash

      end
    end

    sleep 2
    
  end

  get "/" do
    "ROAR!!!"
  end

  post '/git_update' do
    GitUpdate.new.notify(JSON.parse(params[:payload]))
  end
end

# Sinatra::Application::run!