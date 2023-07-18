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

require "logstash/outputs/base"
require "logstash/config/source_loader"
require "logstash/inputs/base"
require "logstash/filters/base"
require "thread"

module LogStash
  module Inputs
    class DummyInput < LogStash::Inputs::Base
      config_name "dummyinput"

      def run(queue)
        # noop
      end
    end

    class DummyBlockingInput < LogStash::Inputs::Base
      config_name "dummyblockinginput"
      milestone 2

      def register
        @latch = java.util.concurrent.CountDownLatch.new(1)
      end

      def run(_)
        @latch.await
      end

      def stop
        @latch.count_down
      end
    end
  end

  module Filters
    class DummyFilter < LogStash::Filters::Base
      config_name "dummyfilter"

      def register
      end

      def filter(event)
        # noop
      end

      ##
      # Returns a one-off subclass of the DummyFilter that
      # executes the provided hook with each event it receives
      def self.with_hook(&block)
        Class.new(self) do
          config_name "dummyfilter_#{__id__}"
          define_method(:filter) do |event|
            block.call(event)
          end
        end
      end
    end
  end

  module Outputs
    class DummyOutput < LogStash::Outputs::Base
      config_name "dummyoutput"
      milestone 2

      attr_reader :num_closes, :events

      def initialize(params = {})
        super
        @num_closes = 0
        @events = []
        @mutex = Mutex.new
      end

      def register
      end

      def receive(event)
        @mutex.lock
        @events << event
      ensure
          @mutex.unlock
      end

      def close
        @num_closes += 1
      end
    end

    class DummyOutputWithEventsArray < LogStash::Outputs::Base
      config_name "dummyoutput2"
      milestone 2

      attr_reader :events

      def initialize(params = {})
        super
        @events = []
      end

      def register
      end

      def receive(event)
        @events << event
      end

      def close
      end
    end

    class DroppingDummyOutput < LogStash::Outputs::Base
      config_name "droppingdummyoutput"
      milestone 2

      attr_reader :num_closes

      def initialize(params = {})
        super
        @num_closes = 0
        @events_received = Concurrent::AtomicFixnum.new(0)
      end

      def register
      end

      def receive(event)
        @events_received.increment
      end

      def events_received
        @events_received.value
      end

      def close
        @num_closes = 1
      end
    end
end end

# A Test Source loader will return the same configuration on every fetch call
class TestSourceLoader
  FailedFetch = LogStash::Config::SourceLoader::FailedFetch
  SuccessfulFetch = LogStash::Config::SourceLoader::SuccessfulFetch

  def initialize(*responses)
    @count = Concurrent::AtomicFixnum.new(0)
    @responses_mutex = Mutex.new
    @responses = coerce_responses(responses)
  end

  def fetch
    @count.increment
    @responses
end

  def fetch_count
    @count.value
  end

  private
  def coerce_responses(responses)
    if responses.size == 1
      response = responses.first

      case response
      when LogStash::Config::SourceLoader::SuccessfulFetch
        response
      when LogStash::Config::SourceLoader::FailedFetch
        response
      else
        LogStash::Config::SourceLoader::SuccessfulFetch.new(Array(response))
      end

    else
      LogStash::Config::SourceLoader::SuccessfulFetch.new(responses)
    end
  end
end

# This source loader will return a new configuration on very call until we ran out.
class TestSequenceSourceLoader
  FailedFetch = LogStash::Config::SourceLoader::FailedFetch
  SuccessfulFetch = LogStash::Config::SourceLoader::SuccessfulFetch

  attr_reader :original_responses

  def initialize(*responses)
    @count = Concurrent::AtomicFixnum.new(0)
    @responses_mutex = Mutex.new
    @responses = responses.collect(&method(:coerce_response))

    @original_responses = @responses.dup
  end

  def fetch
    @count.increment
    response  = @responses_mutex.synchronize { @responses.shift }
    raise "TestSequenceSourceLoader runs out of response" if response.nil?
    response
  end

  def fetch_count
    @count.value
  end

  private
  def coerce_response(response)
    case response
    when LogStash::Config::SourceLoader::SuccessfulFetch
      response
    when LogStash::Config::SourceLoader::FailedFetch
      response
    else
      LogStash::Config::SourceLoader::SuccessfulFetch.new(Array(response))
    end
  end
end
