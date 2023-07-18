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
require "logstash/json"

describe LogStash::Api::Modules::Plugins do
  include_context "api setup"
  include_examples "not found"

  before(:each) do
    get "/"
  end

  it "respond to plugins resource" do
    expect(last_response).to be_ok
  end

  it "return valid json content type" do
    expect(last_response.content_type).to eq("application/json"), "Did not get json, got #{last_response.content_type} / #{last_response.body}"
  end

  context "#schema" do
    it "return the expected schema" do
      expect(JSON::Validator.fully_validate(
        {
          "properties" => {
            "plugins" => {
              "type" => "array",
              "items" => [
                {
                  "type" => "object",
                  "required" => ["version", "name"]
                }
              ]
            },
            "total" => { "type" => "number" }
          },
          "required" => ["plugins", "total"]
        },
        last_response.body)
      ).to be_empty
    end
  end

  context "#values" do
    let(:payload) { LogStash::Json.load(last_response.body) }

    it "return totals of plugins" do
      expect(payload["total"]).to eq(payload["plugins"].count)
    end

    it "return a list of available plugins" do
      payload["plugins"].each do |plugin|
        expect do
          Gem::Specification.find_by_name(plugin["name"])
        end.not_to raise_error
      end
    end

    it "return non empty version values" do
      expect(JSON::Validator.fully_validate(
        { "properties" => { "plugins" => {
          "type" => "array",
          "items" => [
            {
              "type" => "object",
              "properties" => {
                "version" => {
                  "type" => "string",
                  "minLength" => 1
                }
              },
              "required" => ["version"]
            }
          ],
          "minItems" => 1
        } } },
        last_response.body)
      ).to be_empty
    end
  end
end
