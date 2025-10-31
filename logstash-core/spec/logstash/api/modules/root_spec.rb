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

        include_examples "returns without waiting"
      end

      context 'timeout is provided' do

        let(:request) { "/?timeout=#{timeout}" }

        context 'timeout does not have units' do

          let(:timeout) { '1' }

          it 'returns an error response' do
            expect(response.body).to include(described_class::INVALID_TIMEOUT_MESSAGE % [timeout])
          end

          it 'returns a 400 status' do
            expect(response.status).to be 400
          end
        end

        context 'timeout number is not an integer' do

          let(:timeout) { '1.0s' }

          it 'returns an error response' do
            expect(response.body).to include(described_class::INVALID_TIMEOUT_MESSAGE % [timeout])
          end

          it 'returns an 400 status' do
            expect(response.status).to be 400
          end
        end

        context 'timeout is not in the accepted format' do

          let(:timeout) { 'invalid' }

          it 'returns an error response' do
            expect(response.body).to include(described_class::INVALID_TIMEOUT_MESSAGE % [timeout])
          end

          it 'returns an 400 status' do
            expect(response.status).to be 400
          end
        end

        context 'valid timeout is provided' do

          context 'no status is provided' do

            let(:timeout) { '1s' }

            include_examples "returns without waiting"
          end

          context 'status is provided' do

            let(:timeout) { '1s' }
            let(:status) { 'green' }
            let(:request) { "/?status=#{status}timeout=#{timeout}" }

            it 'returns status code 200' do
              expect(response.status).to be 200
            end

            include_examples "returns without waiting"
          end
        end
      end
    end

    context 'status' do

      context 'no status provided' do

        let(:request) { '/'}

        include_examples "returns without waiting"
      end

      context 'status is provided' do

        let(:request) { "/?wait_for_status=#{status}" }

        context 'status is not valid' do

          let(:status) { 'invalid' }

          it 'returns an error response' do
            expect(response.body).to include(described_class::INVALID_HEALTH_STATUS_MESSAGE % [status])
          end

          it 'returns an 400 status' do
            expect(response.status).to be 400
          end
        end

        context 'status is valid' do

          let(:status) { 'red' }

          context 'no timeout is provided' do


          end

          context 'timeout is provided' do

            let(:timeout) { '1s' }
            let(:status) { 'green' }
            let(:request) { "/?wait_for_status=#{status}&timeout=#{timeout}" }

            it 'returns status code 200' do
              expect(response.status).to be 200
            end

            include_examples "returns without waiting"
          end
        end
      end
    end

    context 'timeout and status provided' do

      let(:timeout_num) { 2 }
      let(:timeout_string) { "#{timeout_num}s"}
      let(:status) { 'green' }
      let(:request) { "/?wait_for_status=#{status}&timeout=#{timeout_string}" }

      before do
        allow(@agent.health_observer).to receive(:status).and_return(*return_statuses)
      end

      context "the status doesn't change before the timeout" do

        let(:return_statuses) do
          [
            org.logstash.health.Status::RED
          ]
        end

        it 'checks the status until timeout' do
          start_time = Time.now
          response
          end_time = Time.now
          expect(end_time - start_time).to be >= timeout_num
        end

        it 'returns status code 503' do
          expect(response.status).to eq 503
        end

        it 'returns a message saying the request timed out' do
          expect(response.body).to include(described_class::TIMED_OUT_WAITING_FOR_STATUS_MESSAGE % [status])
        end
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

          it 'checks for the status until timeout' do
            start_time = Time.now
            response
            end_time = Time.now
            expect(end_time - start_time).to be >= timeout_num
          end
        end

        context 'the status changes to green' do

          let(:return_statuses) do
            [
              org.logstash.health.Status::RED,
              org.logstash.health.Status::GREEN
            ]
          end

          it 'checks for the status until the target status is reached' do
            start_time = Time.now
            response
            end_time = Time.now
            expect(end_time - start_time).to be < timeout_num
          end
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

          it 'checks for the status until timeout' do
            start_time = Time.now
            response
            end_time = Time.now
            expect(end_time - start_time).to be >= timeout_num
          end
        end

        context 'the status changes to yellow' do

          let(:return_statuses) do
            [
              org.logstash.health.Status::RED,
              org.logstash.health.Status::YELLOW
            ]
          end

          it 'checks for the status until the yellow status is reached' do
            start_time = Time.now
            response
            end_time = Time.now
            expect(end_time - start_time).to be < timeout_num
          end
        end

        context 'the status changes to green' do

          let(:return_statuses) do
            [
              org.logstash.health.Status::RED,
              org.logstash.health.Status::GREEN
            ]
          end

          it 'checks for the status until a status that is better (green) is reached' do
            start_time = Time.now
            response
            end_time = Time.now
            expect(end_time - start_time).to be < timeout_num
          end
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

          include_examples "returns without waiting"
        end

        context 'the status changes to yellow' do

          let(:return_statuses) do
            [
              org.logstash.health.Status::RED,
              org.logstash.health.Status::YELLOW
            ]
          end

          include_examples "returns without waiting"
        end

        context 'the status changes to green' do

          let(:return_statuses) do
            [
              org.logstash.health.Status::RED,
              org.logstash.health.Status::GREEN
            ]
          end

          include_examples "returns without waiting"
        end
      end
    end
  end
end
