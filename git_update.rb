require 'httparty'
require 'active_support/inflector'

ROOMS = {
  "Test AAA" => "437773",
  "Test Analytics" => "439156",
  "Test App" => "435492",
  "Git Integ Test" => "439499",

  "EE3-Production-Bug-Fixes" => "433748",
  "Product Score" => "433742",
  "Analytics" => "225998",
  "App" => "439155",
  "UI" => "225942"
} 

GIT_COMMUNICATION_CONFIG = {
  "business" => [ROOMS["App"], ROOMS["UI"]],
  "indix.com" => [ROOMS["UI"]]
}

class GitUpdate
  
  def notify payload
    commiter = payload["pusher"]["name"]
    repo_name = payload["repository"]["name"]
    commit_counts = payload["commits"].length
    message = "#{commiter} pushed #{commit_counts} #{"commit".pluralize(commit_counts)} to #{repo_name}"
    payload["commits"].each do |commit|
      commit_message = commit["message"]
      commit_hash = commit["id"][0..9]
      message += "<br/>- #{commit_message} (#{commit_hash})"
    end

    GIT_COMMUNICATION_CONFIG[repo_name].each do |room_id|
      Hipchat.new.hip_post room_id, message, "gray"
    end
  end
    
end