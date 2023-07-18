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
require "json-schema"
require "sinatra"
require "logstash/api/modules/logging"

describe LogStash::Api::Modules::Logging do
  include_context "api setup"

  describe "#logging" do
    context "when setting a logger's log level" do
      it "should return a positive acknowledgement on success" do
        put '/', '{"logger.logstash": "ERROR"}'
        expect(JSON::Validator.fully_validate(
          { "properties" => { "acknowledged" => { "enum" => [true] } } },
          last_response.body)
        ).to be_empty
      end

      it "should throw error when level is invalid" do
        put '/', '{"logger.logstash": "invalid"}'
        expect(JSON::Validator.fully_validate(
          { "properties" => { "error" => { "enum" => ["invalid level[invalid] for logger[logstash]"] } } },
          last_response.body)
        ).to be_empty
      end

      it "should throw error when key logger is invalid" do
        put '/', '{"invalid" : "ERROR"}'
        expect(JSON::Validator.fully_validate(
          { "properties" => { "error" => { "enum" => ["unrecognized option [invalid]"] } } },
          last_response.body)
        ).to be_empty
      end
    end
  end
end
