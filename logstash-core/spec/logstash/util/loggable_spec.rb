# encoding: utf-8
require "logstash/util/loggable"
require "spec_helper"

class LoggerTracer 
  attr_reader :messages

  def initialize()
    @messages = []
  end

  def info(message, attributes = {})
    messages << message
  end
end

class DummyLoggerUseCase
  include LogStash::Util::Loggable

  INSTANCE_METHOD_MESSAGE = "from #instance_method"
  CLASS_METHOD_MESSAGE = "from .class method"

  def instance_method
    logger.info(INSTANCE_METHOD_MESSAGE)
  end

  def self.class_method
    logger.info(CLASS_METHOD_MESSAGE)
  end
end

describe LogStash::Util::Loggable do
  let(:global_logger_tracer) { LoggerTracer.new }
  subject { DummyLoggerUseCase.new }

  before do
    LogStash::Util::Loggable.logger = global_logger_tracer
  end

  after do
    LogStash::Util::Loggable.logger = nil
  end
    
  context "Configuring the logger globally" do
    it "defines global logger" do
      expect(subject.logger).to eq(global_logger_tracer)
    end

    it "works with instance methods" do
      subject.instance_method
      expect(global_logger_tracer.messages.last).to eq(DummyLoggerUseCase::INSTANCE_METHOD_MESSAGE)
    end

    it "works with class methods" do
      DummyLoggerUseCase.class_method
      expect(global_logger_tracer.messages.last).to eq(DummyLoggerUseCase::CLASS_METHOD_MESSAGE)
    end
  end

  context "Configuring a logger for a specific class" do
    let(:local_logger_tracer) { LoggerTracer.new }

    before do
      DummyLoggerUseCase.logger = local_logger_tracer
    end

    it "doesn't change the global logger" do
      expect(LogStash::Util::Loggable.logger).to eq(global_logger_tracer)
    end

    it "changes the logger for the class" do
      expect(subject.logger).to eq(local_logger_tracer)
    end

    it "works with instance methods" do
      subject.instance_method
      expect(local_logger_tracer.messages.last).to eq(DummyLoggerUseCase::INSTANCE_METHOD_MESSAGE)
    end

    it "works with class methods" do
      DummyLoggerUseCase.class_method
      expect(local_logger_tracer.messages.last).to eq(DummyLoggerUseCase::CLASS_METHOD_MESSAGE)
    end
  end
end

