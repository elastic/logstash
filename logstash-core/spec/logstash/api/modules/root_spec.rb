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

    let(:margin_of_error) { 0.1 }

    context 'no timeout is provided' do

      let(:return_time) { 0.1 }

      it 'returns immediately' do
        start_time = Time.now
        get "/?wait_for_status=red"
        end_time = Time.now
        expect(end_time - start_time).to be_within(margin_of_error).of(return_time)
      end
    end

    context "timeout is provided" do

      let(:timeout) { 1 }

      context "the status doesn't change" do

        let(:return_time) { timeout + 0.1 }

        it 'checks the status until the timeout is reached' do
          start_time = Time.now
          get "/?wait_for_status=red&timeout=#{timeout}"
          end_time = Time.now
          expect(end_time - start_time).to be_within(margin_of_error).of(return_time)
        end
      end

      context 'the status changes within the timeout' do

        let(:timeout) { 2 }

        let(:return_statuses) do
          [
            org.logstash.health.Status::GREEN,
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

    java.util.EnumSet.allOf(org.logstash.health.Status).each do |status|

      context "#{status} is provided" do

        let(:timeout) do
          # Two statuses are checked before the target is reached. The first wait time is 1 second,
          # the second wait time is 2 seconds. So it takes at least 3 seconds to reach target status.
          3.1
        end

        let(:return_statues) do
          # Make the target status last in the returned values
          statuses = java.util.EnumSet.allOf(org.logstash.health.Status).to_a
          statuses.delete(status)
          statuses << status
        end

        before do
          allow(@agent.health_observer).to receive(:status).and_return(*return_statues)
        end

        it 'checks for the status until it changes' do
          start_time = Time.now
          get "/?wait_for_status=#{status}&timeout=#{timeout}"
          end_time = Time.now
          expect(end_time - start_time).to be < timeout
        end
      end
    end

    context 'status string is formatted differently' do

      let(:timeout) { 2 }

      let(:return_time) do
        # We wait 1 second to check the status a second time. The target status
        # is reached on the second check.
        1.1
      end

      let(:return_statuses) do
        [
          org.logstash.health.Status::GREEN,
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
        expect(end_time - start_time).to be_within(margin_of_error).of(return_time)
      end
    end

    context "invalid status is provided" do

      let(:timeout) { 2 }
      let(:return_time) { 0.1 }

      it 'returns immediately' do
        start_time = Time.now
        get "/?wait_for_status=invalid&timeout=#{timeout}"
        end_time = Time.now
        expect(end_time - start_time).to be_within(margin_of_error).of(return_time)
      end
    end
  end
end
