require 'httparty'
require 'nokogiri'

class Cruisecontrolrb
  
  include HTTParty
  
  def initialize base_url, username = nil, password = nil
    @auth = { :username => username, :password => password }
    @base_url = base_url
  end
  
  def fetch
    options = { :basic_auth => @auth }
    noko = Nokogiri::XML(self.class.get("http://#{@base_url}/XmlStatusReport.aspx", options).parsed_response)
    return {} unless noko.search("Project").first
    { :lastBuildStatus => noko.search("Project").first.attributes["lastBuildStatus"].value,
      :webUrl => noko.search("Project").first.attributes["webUrl"].value,
      :lastBuildLabel => noko.search("Project").first.attributes["lastBuildLabel"].value }
  end
  
end