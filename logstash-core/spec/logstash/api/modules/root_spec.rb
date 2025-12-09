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
require "logstash/api/modules/root"

describe LogStash::Api::Modules::Root do
  include_context "api setup"

  it "should respond to root resource" do
    get "/"
    expect(last_response).to be_ok
  end

  include_examples "not found"

  describe 'wait_for_status' do

    let(:response) { get request }

    context 'timeout' do

      context 'no timeout provided' do

        let(:request) { "/" }

        include_examples "returns successfully without waiting"
      end

      context 'timeout is provided' do

        let(:request) { "/?timeout=#{timeout}" }

        context 'timeout does not have units' do

          let(:timeout) { '1' }
          let(:error_message) { described_class::INVALID_TIMEOUT_MESSAGE % [timeout] }

          include_examples 'bad request response'
        end

        context 'timeout number is not an integer' do

          let(:timeout) { '1.0s' }
          let(:error_message) { described_class::INVALID_TIMEOUT_MESSAGE % [timeout] }

          include_examples 'bad request response'
        end

        context 'timeout is not in the accepted format' do

          let(:timeout) { 'invalid' }
          let(:error_message) { described_class::INVALID_TIMEOUT_MESSAGE % [timeout] }

          include_examples 'bad request response'
        end

        context 'valid timeout is provided' do

          context 'no status is provided' do

            let(:timeout) { '1s' }

            include_examples "returns successfully without waiting"
          end

          context 'status is provided' do

            let(:timeout_num) { 2 }
            let(:timeout_string) { "#{timeout_num}s"}
            let(:status) { 'green' }
            let(:request) { "/?wait_for_status=#{status}&timeout=#{timeout_string}" }

            let(:return_statuses) do
              [
                org.logstash.health.Status::RED,
                org.logstash.health.Status::GREEN

              ]
            end

            it 'returns status code 200' do
              expect(response.status).to be 200
            end

            include_examples "waits until the target status (or better) is reached and returns successfully"
          end
        end
      end
    end

    context 'status' do

      context 'no status provided' do

        let(:request) { '/'}

        include_examples "returns successfully without waiting"
      end

      context 'status is provided' do

        context 'status is not valid' do

          let(:status) { 'invalid' }
          let(:error_message) { described_class::INVALID_HEALTH_STATUS_MESSAGE % [status] }
          let(:request) { "/?wait_for_status=#{status}&timeout=1s" }

          include_examples 'bad request response'
        end

        context 'status is valid' do

          context 'no timeout is provided' do

            let(:request) { "/?wait_for_status=green" }
            let(:error_message) { described_class::TIMEOUT_REQUIRED_WITH_STATUS_MESSAGE }

            include_examples "bad request response"
          end

          context 'timeout is provided' do

            let(:timeout_num) { 2 }
            let(:timeout_string) { "#{timeout_num}s"}
            let(:status) { 'green' }
            let(:request) { "/?wait_for_status=#{status}&timeout=#{timeout_string}" }

            let(:return_statuses) do
              [
                org.logstash.health.Status::RED,
                org.logstash.health.Status::GREEN

              ]
            end

            include_examples 'waits until the target status (or better) is reached and returns successfully'
          end
        end
      end
    end

    context 'timeout and status provided' do

      let(:timeout_num) { 2 }
      let(:timeout_units) { 's' }
      let(:timeout_string) { "#{timeout_num}#{timeout_units}"}
      let(:status) { 'green' }
      let(:request) { "/?wait_for_status=#{status}&timeout=#{timeout_string}" }

      context "the status doesn't change before the timeout" do

        let(:return_statuses) do
          [
            org.logstash.health.Status::RED
          ]
        end

        include_examples 'times out waiting for target status (or better)'
      end

      context 'target status is green' do

        let(:status) { 'green' }

        context 'the status does not change' do

          let(:return_statuses) do
            [
              org.logstash.health.Status::RED,
              org.logstash.health.Status::YELLOW
            ]
          end

          include_examples 'times out waiting for target status (or better)'
        end

        context 'the status changes to green' do

          let(:return_statuses) do
            [
              org.logstash.health.Status::RED,
              org.logstash.health.Status::GREEN
            ]
          end

          include_examples 'waits until the target status (or better) is reached and returns successfully'
        end

        context 'the current status is unknown' do

          let(:return_statuses) do
            [
              org.logstash.health.Status::UNKNOWN,
              org.logstash.health.Status::GREEN
            ]
          end

          include_examples 'waits until the target status (or better) is reached and returns successfully'
        end
      end

      context 'target status is yellow' do

        let(:status) { 'yellow' }

        context 'the status does not change' do

          let(:return_statuses) do
            [
              org.logstash.health.Status::RED
            ]
          end

          include_examples 'times out waiting for target status (or better)'
        end

        context 'the status changes to yellow' do

          let(:return_statuses) do
            [
              org.logstash.health.Status::RED,
              org.logstash.health.Status::YELLOW
            ]
          end

          include_examples 'waits until the target status (or better) is reached and returns successfully'
        end

        context 'the status changes to green' do

          let(:return_statuses) do
            [
              org.logstash.health.Status::RED,
              org.logstash.health.Status::GREEN
            ]
          end

          include_examples 'waits until the target status (or better) is reached and returns successfully'
        end
      end

      context 'target status is red' do

        let(:status) { 'red' }

        context 'the status does not change' do

          let(:return_statuses) do
            [
              org.logstash.health.Status::RED
            ]
          end

          include_examples "returns successfully without waiting"
        end

        context 'the status changes to yellow' do

          let(:return_statuses) do
            [
              org.logstash.health.Status::RED,
              org.logstash.health.Status::YELLOW
            ]
          end

          include_examples "returns successfully without waiting"
        end

        context 'the status changes to green' do

          let(:return_statuses) do
            [
              org.logstash.health.Status::RED,
              org.logstash.health.Status::GREEN
            ]
          end

          include_examples "returns successfully without waiting"
        end
      end

      context 'timeout units is ms' do

        let(:timeout_units) { 'ms' }

        context "the status doesn't change before the timeout" do

          let(:return_statuses) do
            [
              org.logstash.health.Status::RED
            ]
          end

          include_examples 'times out waiting for target status (or better)'
        end
      end
    end
  end
end
