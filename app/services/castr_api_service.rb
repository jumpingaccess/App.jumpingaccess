# app/services/castr_api_service.rb
require 'httparty'

class CastrApiService
  API_URL = 'https://api.castr.com/v2/live_streams'

  def self.api_key
    ApiCredential.for_provider('castr')&.api_key
  end

  def self.fetch_streams
    key = api_key
    return { success: false, message: "Clé API Castr.io non définie." } unless key

    response = HTTParty.get(API_URL, headers: {
      
      'authorization' => "Basic #{key}",
      "Content-Type" => "application/json"
    })

    return handle_error(response)
    rescue StandardError => e
      { success: false, message: "Erreur lors de l'appel à l'API Castr.io : #{e.message}" }
  end

  def self.handle_error(response)
    if response.code == 200
      data = response.parsed_response
      { success: true, data: data }
    else
      { success: false, message: "Erreur API Castr.io : code #{response.code}" }
    end
  end

  def self.fetch_endpoints(stream_id)
    all_streams = fetch_streams

    unless all_streams[:success]
      return { success: false, message: all_streams[:message] }
    end

    # ✅ JSON v2 : structure = { docs: [...] }
    streams = all_streams[:data]["docs"]
    stream = streams.find { |s| s["_id"] == stream_id }

    if stream
      platforms = stream["platforms"] || []
      { success: true, data: platforms }
    else
      { success: false, message: "Stream introuvable pour ID : #{stream_id}" }
    end
  end

end

##
# Access Token ID: qc6uL3XYuvR1
# Secret Key : x9A7hnbLEoNqlWVQgwam4wQJR2krciO7QpWy
# base64 : cWM2dUwzWFl1dlIxOng5QTdobmJMRW9OcWxXVlFnd2FtNHdRSlIya3JjaU83UXBXeQ==
##