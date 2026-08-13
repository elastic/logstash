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

require "spec_helper"

require "sinatra"
require "logstash/api/modules/health_report"

describe LogStash::Api::Modules::HealthReport do
  include_context "api setup"

  include_examples "not found"

  describe "GET /" do
    before(:each) { get "/" }

    it "returns 200" do
      expect(last_response).to be_ok
    end

    it "includes a timestamp in ISO 8601 format with sub-second precision" do
      body = JSON.parse(last_response.body)
      expect(body).to include("timestamp")
      expect(body["timestamp"]).to match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}(\d{3}(\d{3})?)?Z\z/)
    end
  end
end
