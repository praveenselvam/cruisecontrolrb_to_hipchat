require 'httparty'

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
  "hook-bot" => [ROOMS["Git Integ Test"]],
  "business" => [ROOMS["App"], ROOMS["UI"]],
  "indix.com" => [ROOMS["UI"]],
  "forge-ui" => [ROOMS["UI"]],
  "apeiron" => [ROOMS["Analytics"]],
  "analytics-service" => [ROOMS["Analytics"]],
  "analytics-jobs" => [ROOMS["Analytics"]],
  "oogway" => [ROOMS["Analytics"]],
  "tao" => [ROOMS["Analytics"]]
}

class GitUpdate
  
  def notify payload
    commiter = payload["pusher"]["name"]
    repo_name = payload["repository"]["name"]
    commit_counts = payload["commits"].length
    message = "#{commiter} pushed #{commit_counts} #{commit_counts > 1 ? "commits" : "commit"} to #{repo_name}"
    payload["commits"].each do |commit|
      commit_message = commit["message"]
      commit_url = commit["url"]
      commit_hash = commit["id"][0..9]
      message += "<br/>- #{commit_message} (<a href='#{commit_url}'>#{commit_hash})</a>"
    end

    GIT_COMMUNICATION_CONFIG[repo_name].each do |room_id|
      Hipchat.new.hip_post room_id, message, "gray"
    end
  end
    
end