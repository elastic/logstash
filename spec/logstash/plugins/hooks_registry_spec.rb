# encoding: utf-8
require "logstash/event_dispatcher"
require "logstash/plugins/hooks_registry"

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
    expect { subject.register_emitter(emitter.class, emitter.dispatcher) }.to change { subject.emmitters_count }.by(1)
  end

  it "allow to remove an emitter" do
    subject.register_emitter(emitter.class, emitter.dispatcher)
    expect { subject.remove_emitter(emitter.class)}.to change { subject.emmitters_count }.by(-1)
  end

  it "allow to register hooks to emitters" do
    expect { subject.register_hooks(emitter.class, listener) }.to change { subject.hooks_count }.by(1)
    expect { subject.register_hooks(emitter.class, listener) }.to change { subject.hooks_count(emitter.class) }.by(1)
  end

  it "link the emitter class to the listener" do
    subject.register_emitter(emitter.class, emitter.dispatcher)
    subject.register_hooks(emitter.class, listener)

    expect(listener.work?).to be_falsey
    emitter.do_work

    expect(listener.work?).to be_truthy
  end
end
