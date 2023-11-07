# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require "manticore"
require "json"

# Convenience class to interact with the HTTP monitoring APIs
class MonitoringAPI

  def initialize(port = 9600)
    @port = port
  end

  def pipeline_stats(pipeline_id)
    resp = Manticore.get("http://localhost:#{@port}/_node/stats/pipelines/#{pipeline_id}").body
    stats_response = JSON.parse(resp)
    stats_response.fetch("pipelines").fetch(pipeline_id)
  end

  def event_stats
    resp = Manticore.get("http://localhost:#{@port}/_node/stats").body
    stats_response = JSON.parse(resp)
    stats_response["events"]
  end

  def version
    request = @agent.get("http://localhost:#{@port}/")
    response = request.execute
    r = JSON.parse(response.body.read)
    r["version"]
  end

  def node_info
    resp = Manticore.get("http://localhost:#{@port}/_node").body
    JSON.parse(resp)
  end

  def node_stats
    resp = Manticore.get("http://localhost:#{@port}/_node/stats").body
    JSON.parse(resp)
  end

  def logging_get
    resp = Manticore.get("http://localhost:#{@port}/_node/logging").body
    JSON.parse(resp)
  end

  def logging_put(body)
    resp = Manticore.put("http://localhost:#{@port}/_node/logging", {headers: {"Content-Type" => "application/json"}, body: body.to_json }).body
    JSON.parse(resp)
  end

  def logging_reset
    resp = Manticore.put("http://localhost:#{@port}/_node/logging/reset", {headers: {"Content-Type" => "application/json"}}).body
    JSON.parse(resp)
  end
end
