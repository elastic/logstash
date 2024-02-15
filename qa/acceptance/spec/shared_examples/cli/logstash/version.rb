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

require_relative "../../../spec_helper"
require "logstash/version"

shared_examples "logstash version" do |logstash|
  describe "logstash --version" do
    before :all do
      logstash.install({:version => LOGSTASH_VERSION})
      logstash.write_default_pipeline
    end

    after :all do
      logstash.uninstall
    end

    context "on [#{logstash.human_name}]" do
      it "returns the right logstash version" do
        result = logstash.run_command_in_path("bin/logstash --version")
        expect(result).to run_successfully_and_output(/#{LOGSTASH_VERSION}/)
      end
      context "when also using the --path.settings argument" do
        it "returns the right logstash version" do
          result = logstash.run_command_in_path("bin/logstash --path.settings=/etc/logstash --version")
          expect(result).to run_successfully_and_output(/#{LOGSTASH_VERSION}/)
        end
      end
    end
  end
end
