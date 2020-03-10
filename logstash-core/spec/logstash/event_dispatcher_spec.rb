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

describe LogStash::EventDispatcher do
  class DummyEmitter
    attr_reader :dispatcher

    def initialize
      @dispatcher = LogStash::EventDispatcher.new(self)
    end

    def method_exists
      dispatcher.fire(:method_exists)
    end

    def method_exists_with_arguments(argument1, argument2, argument3)
      dispatcher.fire(:method_exists_with_arguments, argument1, argument2, argument3)
    end

    def method_do_not_exist
      dispatcher.fire(:method_do_not_exist)
    end
  end

  class CustomSpy
    def method_exists
    end

    def method_exists_with_arguments(argument1, argument2, argument3)
    end
  end

  let(:listener) { CustomSpy }
  subject(:emitter) { DummyEmitter.new }

  it "ignores duplicate listener" do
    emitter.dispatcher.add_listener(listener)
    emitter.dispatcher.add_listener(listener)
    expect(listener).to receive(:method_exists).with(emitter).once
    emitter.method_exists
  end

  describe "Emits events" do
    before do
      emitter.dispatcher.add_listener(listener)
    end

    context "when the method exist" do
      it "calls the method without arguments" do
        expect(listener).to receive(:method_exists).with(emitter)
        emitter.method_exists
      end

      it "calls the method with arguments" do
        expect(listener).to receive(:method_exists_with_arguments).with(emitter, 1, 2, 3)
        emitter.method_exists_with_arguments(1, 2, 3)
      end
    end

    context "when the method doesn't exist on the listener" do
      it "should not raise an exception" do
        expect { emitter.method_do_not_exist }.not_to raise_error
      end
    end
  end

  describe "Configuring listeners" do
    it "adds a listener to an emitter" do
      expect(listener).to receive(:method_exists).with(emitter)
      emitter.dispatcher.add_listener(listener)
      emitter.method_exists
    end

    it "allows to remove a listener to an emitter" do
      expect(listener).to receive(:method_exists).with(emitter).once
      emitter.dispatcher.add_listener(listener)
      emitter.method_exists
      emitter.dispatcher.remove_listener(listener)
      emitter.method_exists
    end
  end
end
