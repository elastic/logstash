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

  describe 'wait_for_status query param' do
    
    context 'no timeout is provided' do

      it 'returns immediately' do
        start_time = Time.now
        get "/?wait_for_status=red"
        end_time = Time.now
        expect(end_time - start_time).to be < 0.5
      end
    end

    context "timeout is provided" do

      context "the timeout value is not a valid integer" do

        let(:timeout) { "invalid" }

        it 'returns immediately' do
          start_time = Time.now
          get "/?wait_for_status=red&timeout=#{timeout}"
          end_time = Time.now
          expect(end_time - start_time).to be < 0.5
        end
      end

      context "the status doesn't change" do

        let(:timeout) { 1 }

        let(:return_statuses) do
          [
            org.logstash.health.Status::RED
          ]
        end

        before do
          allow(@agent.health_observer).to receive(:status).and_return(*return_statuses)
        end

        it 'checks the status until the timeout is reached' do
          start_time = Time.now
          get "/?wait_for_status=green&timeout=#{timeout}"
          end_time = Time.now
          expect(end_time - start_time).to be >= timeout
        end

        it 'returns status code 503' do
          response = get "/?wait_for_status=green&timeout=#{timeout}"
          expect(response.status).to eq 503
        end
      end

      context 'the status changes to the target status within the timeout' do

        let(:timeout) do
          # The first wait interval is 1 second
          2
        end

        let(:return_statuses) do
          [
            org.logstash.health.Status::RED,
            org.logstash.health.Status::YELLOW
          ]
        end

        before do
          allow(@agent.health_observer).to receive(:status).and_return(*return_statuses)
        end

        it 'returns when the target status is reached' do
          start_time = Time.now
          get "/?wait_for_status=yellow&timeout=#{timeout}"
          end_time = Time.now
          expect(end_time - start_time).to be < timeout
        end
      end
    end

    context 'status is provided' do

      context 'no timeout' do

        described_class::HEALTH_STATUS.each do |status|

          context "with status \"#{status}\"" do

            it 'returns immediately' do
              start_time = Time.now
              get "/?wait_for_status=#{status}"
              end_time = Time.now
              expect(end_time - start_time).to be < 0.5
            end
          end
        end
      end

      context "invalid status" do

        it "pending", :skip do
          # start_time = Time.now
          # get "/?wait_for_status=invalid"
          # end_time = Time.now
          # expect(end_time - start_time).to be < 0.5
        end
      end

      context 'status is formatted differently' do

        let(:timeout) { 2 }

        let(:return_statuses) do
          [
            org.logstash.health.Status::RED,
            org.logstash.health.Status::YELLOW
          ]
        end

        before do
          allow(@agent.health_observer).to receive(:status).and_return(*return_statuses)
        end

        it 'normalizes the format and checks the status' do
          start_time = Time.now
          get "/?wait_for_status=yElLoW&timeout=#{timeout}"
          end_time = Time.now
          expect(end_time - start_time).to be < timeout
        end
      end

      context 'target status is green' do

        let(:timeout) { 2 }

        context 'the status does not change' do

          let(:return_statuses) do
            [
              org.logstash.health.Status::RED,
              org.logstash.health.Status::YELLOW
            ]
          end

          before do
            allow(@agent.health_observer).to receive(:status).and_return(*return_statuses)
          end

          it 'checks for the status until the timeout is reached' do
            start_time = Time.now
            get "/?wait_for_status=green&timeout=#{timeout}"
            end_time = Time.now
            expect(end_time - start_time).to be >= timeout
          end
        end

        context 'the status changes to green' do

          let(:timeout) { 2 }

          let(:return_statuses) do
            [
              org.logstash.health.Status::RED,
              org.logstash.health.Status::GREEN
            ]
          end

          before do
            allow(@agent.health_observer).to receive(:status).and_return(*return_statuses)
          end

          it 'checks for the status until the timeout is reached' do
            start_time = Time.now
            get "/?wait_for_status=green&timeout=#{timeout}"
            end_time = Time.now
            expect(end_time - start_time).to be < timeout
          end
        end
      end

      context 'target status is yellow' do

        let(:timeout) { 2 }

        context 'the status does not change' do

          let(:return_statuses) do
            [
              org.logstash.health.Status::RED
            ]
          end

          before do
            allow(@agent.health_observer).to receive(:status).and_return(*return_statuses)
          end

          it 'checks for the status until the timeout is reached' do
            start_time = Time.now
            get "/?wait_for_status=yellow&timeout=#{timeout}"
            end_time = Time.now
            expect(end_time - start_time).to be >= timeout
          end
        end

        context 'the status changes to yellow' do

          let(:timeout) { 2 }

          let(:return_statuses) do
            [
              org.logstash.health.Status::RED,
              org.logstash.health.Status::YELLOW
            ]
          end

          before do
            allow(@agent.health_observer).to receive(:status).and_return(*return_statuses)
          end

          it 'checks for the status until the yellow status is reached' do
            start_time = Time.now
            get "/?wait_for_status=yellow&timeout=#{timeout}"
            end_time = Time.now
            expect(end_time - start_time).to be < timeout
          end
        end

        context 'the status changes to green' do

          let(:timeout) { 2 }

          let(:return_statuses) do
            [
              org.logstash.health.Status::RED,
              org.logstash.health.Status::GREEN
            ]
          end

          before do
            allow(@agent.health_observer).to receive(:status).and_return(*return_statuses)
          end

          it 'checks for the status until a status that is better (green) is reached' do
            start_time = Time.now
            get "/?wait_for_status=yellow&timeout=#{timeout}"
            end_time = Time.now
            expect(end_time - start_time).to be < timeout
          end
        end
      end

      context 'target status is red' do

        let(:timeout) { 2 }

        context 'the status does not change' do

          let(:return_statuses) do
            [
              org.logstash.health.Status::RED
            ]
          end

          before do
            allow(@agent.health_observer).to receive(:status).and_return(*return_statuses)
          end

          it 'returns immediately' do
            start_time = Time.now
            get "/?wait_for_status=red&timeout=#{timeout}"
            end_time = Time.now
            expect(end_time - start_time).to be < 0.5
          end
        end

        context 'the status changes to yellow' do

          let(:timeout) { 2 }

          let(:return_statuses) do
            [
              org.logstash.health.Status::RED,
              org.logstash.health.Status::YELLOW
            ]
          end

          before do
            allow(@agent.health_observer).to receive(:status).and_return(*return_statuses)
          end

          it 'returns immediately' do
            start_time = Time.now
            get "/?wait_for_status=red&timeout=#{timeout}"
            end_time = Time.now
            expect(end_time - start_time).to be < 0.5
          end
        end

        context 'the status changes to green' do

          let(:timeout) { 2 }

          let(:return_statuses) do
            [
              org.logstash.health.Status::RED,
              org.logstash.health.Status::GREEN
            ]
          end

          before do
            allow(@agent.health_observer).to receive(:status).and_return(*return_statuses)
          end

          it 'returns immediately' do
            start_time = Time.now
            get "/?wait_for_status=red&timeout=#{timeout}"
            end_time = Time.now
            expect(end_time - start_time).to be < 0.5
          end
        end
      end
    end
  end
end
