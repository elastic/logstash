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
require "logstash/api/modules/plugins"

describe LogStash::Api::Modules::Plugins do
  include_context "api setup"
  include_examples "not found"

  extend ResourceDSLMethods

  before(:each) do
    get "/"
  end

  describe "retrieving plugins" do
    it "should return OK" do
      expect(last_response).to be_ok
    end

    it "should return a list of plugins" do
      expect(JSON::Validator.fully_validate(
        {
          "properties" => {
            "plugins" => {
              "type" => "array"
            },
            "required" => ["plugins"]
          }
        },
        last_response.body)
      ).to be_empty
    end

    it "should return the total number of plugins" do
      expect(JSON::Validator.fully_validate(
        {
          "properties" => {
            "total" => {
              "type" => "number"
            },
            "required" => ["total"]
          }
        },
        last_response.body)
      ).to be_empty
    end
  end
end
