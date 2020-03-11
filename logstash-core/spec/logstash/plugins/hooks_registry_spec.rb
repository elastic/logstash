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

describe LogStash::Plugins::HooksRegistry do
  class DummyEmitter
    attr_reader :dispatcher

    def initialize
      @dispatcher = LogStash::EventDispatcher.new(self)
    end

    def do_work
      dispatcher.fire(:do_work)
    end
  end

  class DummyListener
    def initialize
      @work = false
    end

    def do_work(emitter = nil)
      @work = true
    end

    def work?
      @work
    end
  end

  subject { described_class.new }

  let(:emitter) { DummyEmitter.new }
  let(:listener) { DummyListener.new }

  it "allow to register an emitter" do
    expect { subject.register_emitter(emitter.class, emitter.dispatcher) }.to change { subject.emitters_count }.by(1)
  end

  it "allow to remove an emitter" do
    subject.register_emitter(emitter.class, emitter.dispatcher)
    expect { subject.remove_emitter(emitter.class)}.to change { subject.emitters_count }.by(-1)
  end

  it "allow to register hooks to emitters" do
    expect { subject.register_hooks(emitter.class, listener) }.to change { subject.hooks_count }.by(1)
    expect { subject.register_hooks(emitter.class, listener) }.to change { subject.hooks_count(emitter.class) }.by(1)
  end

  it "verifies if a hook is registered to a specific emitter scope" do
    subject.register_hooks(emitter.class, listener)
    expect(subject.registered_hook?(emitter.class, listener.class)).to be_truthy
    expect(subject.registered_hook?(Class.new, listener.class)).to be_falsey
  end

  it "link the emitter class to the listener" do
    subject.register_emitter(emitter.class, emitter.dispatcher)
    subject.register_hooks(emitter.class, listener)

    expect(listener.work?).to be_falsey
    emitter.do_work

    expect(listener.work?).to be_truthy
  end
end
