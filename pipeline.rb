require 'httparty'
require 'nokogiri'
require 'json'

class Pipeline
  
  include HTTParty
  
  def initialize base_url, username = nil, password = nil, pipeline_name
    @auth = { :username => username, :password => password }
    @base_url = base_url
    @pipeline_name = pipeline_name
  end
  
  def fetch
    options = { :basic_auth => @auth }

    noko = Nokogiri::XML(self.class.get("#{@base_url}go/api/pipelines/#{@pipeline_name}/stages.xml", options).parsed_response)

    status_hash = {
      :title => noko.search("entry").search("link").first.attributes["title"].value,
      :href => noko.search("entry").search("link").first.attributes["href"].value
    }

    res = JSON.parse HTTParty.get(status_hash[:href], options).to_s.gsub("=>", ":")
    res["website_link"] = noko.search("entry").search("id").first.content

    return res
  end
  
end