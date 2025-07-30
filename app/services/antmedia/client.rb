class Antmedia::Client
  include HTTParty
  base_uri "http://ott.jumpingaccess.com:5080/LiveApp/rest"

  def initialize
    cred = ApiCredential.find_by(name: 'antmedia')
    LoggerService.log_action("-", 'Videos', cred)

    @headers = {
      "Authorization" => "Bearer #{cred.api_key}",
      "Content-Type" => "application/json"
    }
  end

  def list_streams(offset: 0, size: 20)
    response = self.class.get("/v2/broadcasts/list/#{offset}/#{size}", headers: @headers)
  end
      # Méthode à ajouter :
  def delete_stream(stream_id)
    self.class.delete("/v2/broadcasts/#{stream_id}", headers: @headers)
  end
  def create_stream(payload)
    self.class.post("/v2/broadcasts/create", headers: @headers, body: payload.to_json)
  end
  def stream_stats(stream_id)
    self.class.get("/v2/broadcasts/#{stream_id}", headers: @headers)
  end
end
