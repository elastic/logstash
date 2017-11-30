require "manticore"
require "json"

# Convenience class to interact with the HTTP monitoring APIs
class MonitoringAPI

  def pipeline_stats(pipeline_id)
    resp = Manticore.get("http://localhost:9600/_node/stats/pipelines/#{pipeline_id}").body
    stats_response = JSON.parse(resp)
    stats_response.fetch("pipelines").fetch(pipeline_id)
  end

  def event_stats
    resp = Manticore.get("http://localhost:9600/_node/stats").body
    stats_response = JSON.parse(resp)
    stats_response["events"]
  end

  def version
    request = @agent.get("http://localhost:9600/")
    response = request.execute
    r = JSON.parse(response.body.read)
    r["version"]
  end
  
  def node_info
    resp = Manticore.get("http://localhost:9600/_node").body
    JSON.parse(resp)
  end

  def node_stats
    resp = Manticore.get("http://localhost:9600/_node/stats").body
    JSON.parse(resp)
  end

  def logging_get
    resp = Manticore.get("http://localhost:9600/_node/logging").body
    JSON.parse(resp)
  end

  def logging_put(body)
    resp = Manticore.put("http://localhost:9600/_node/logging", {headers: {"Content-Type" => "application/json"}, body: body.to_json }).body
    JSON.parse(resp)
  end

  def logging_reset
    resp = Manticore.put("http://localhost:9600/_node/logging/reset", {headers: {"Content-Type" => "application/json"}}).body
    JSON.parse(resp)
  end
end
