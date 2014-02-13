require 'httparty'
require 'nokogiri'
require 'json'

class Pipeline
  
  include HTTParty
  
  def initialize base_url, username = nil, password = nil, pipeline_name, stage_name
    @auth = { :username => username, :password => password }
    @base_url = base_url
    @pipeline_name = pipeline_name
    @stage_name = stage_name
  end
  
  def fetch
    options = { :basic_auth => @auth }

    noko = Nokogiri::XML(self.class.get("#{@base_url}go/api/pipelines/#{@pipeline_name}/stages.xml", options).parsed_response)

    status_hash = {
      :title => "#{@stage_name} Stage Detail",
      :feed_url => noko.search("entry/link[@title='#{@stage_name} Stage Detail']").first.attributes["href"]
    }

    stage_info = JSON.parse HTTParty.get(status_hash[:feed_url], options).to_s.gsub("=>", ":")
    stage_info["website_link"] = "#{@base_url}go/pipelines/#{@pipeline_name}/#{stage_info["stage"]["pipeline"]["label"]}/#{@stage_name}/#{stage_info["stage"]["counter"]}"

    return stage_info
  end
  
end