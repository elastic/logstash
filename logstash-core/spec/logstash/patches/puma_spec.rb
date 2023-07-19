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

describe LogStash::DelegatingLogWriter do
  let(:logger) { double("Logger") }
  let(:text) { 'foo bar'}
  let(:req) { { status: 200 } }
  let(:error) do
    Class.new(StandardError) do
      def self.backtrace
        %w[foo.rb bar.rb]
      end
    end
  end

  subject { LogStash::DelegatingLogWriter.new(logger) }

  before(:each) do
    allow(logger).to receive(:debug?).and_return(true)
  end

  context "#log" do
    it "should log a :debug message" do
      expect(logger).to receive(:debug).with(text)
      subject.send(:log, text)
    end
  end

  context "#write" do
    it "should log a raw :debug message" do
      expect(logger).to receive(:debug).with(1)
      subject.send(:write, 1)
    end
  end

  context "#debug" do
    it "should log a :debug message" do
      expect(logger).to receive(:debug).with(text)
      subject.send(:debug, text)
    end
  end

  context "#error" do
    it "should log an :error message and raise LogStash::UnrecoverablePumaError" do
      expect(logger).to receive(:error).with(text)
      expect { subject.send(:error, text) }.to raise_error(LogStash::UnrecoverablePumaError, text)
    end
  end

  context "#connection_error" do
    it "should log a :debug message" do
      expect(logger).to receive(:debug).with(text, { error: error, req: req, backtrace: error.backtrace })
      subject.send(:connection_error, error, req, text)
    end
  end

  context "#parse_error" do
    it "should log a :debug message" do
      expect(logger).to receive(:debug).with(anything, { error: error, req: req })
      subject.send(:parse_error, error, req)
    end
  end

  context "#ssl_error" do
    it "should log a :debug message with the peer certificate details" do
      socket = double("Socket")
      peercert = double("Peercert")

      allow(socket).to receive(:peeraddr).and_return(%w[first second last])
      allow(peercert).to receive(:subject).and_return("logstash")
      allow(socket).to receive(:peercert).and_return(peercert)

      expect(logger).to receive(:debug).with('SSL error, peer: last, peer cert: logstash', { error: error })
      subject.send(:ssl_error, error, socket)
    end
  end

  context "#unknown_error" do
    it "should log an :error message" do
      expect(logger).to receive(:error).with(text, { error: error, req: req, backtrace: error.backtrace })
      subject.send(:unknown_error, error, req, text)
    end

    context 'when debug log level is disabled' do
      it "should not include the :backtrace field on the :error log message" do
        allow(logger).to receive(:debug?).and_return(false)
        expect(logger).to receive(:error).with(text, { error: error, req: req })
        subject.send(:unknown_error, error, req, text)
      end
    end
  end

  context "#debug_error" do
    it "should log a :debug message" do
      expect(logger).to receive(:debug).with(text, { error: error, req: req, backtrace: error.backtrace })
      subject.send(:debug_error, error, req, text)
    end
  end
end
