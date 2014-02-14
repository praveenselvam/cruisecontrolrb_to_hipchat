require 'httparty'

class Hipchat
  include HTTParty
  
  def hip_post room_id, from, message, color = nil, notify = 0
    self.class.post("https://api.hipchat.com/v1/rooms/message?" + 
      "auth_token=#{ENV["HIPCHAT_AUTH_TOKEN"]}" +
      "&message=#{URI.escape(message)}" +
      "&from=#{from}" +
      "&room_id=#{room_id}" + 
      "&notify=#{notify}" + 
      "&color=#{color}")
  end
    
end