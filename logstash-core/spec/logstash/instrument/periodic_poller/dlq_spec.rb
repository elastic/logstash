# encoding: utf-8
require "spec_helper"
require "logstash/instrument/periodic_poller/dlq"
require "logstash/instrument/collector"

describe LogStash::Instrument::PeriodicPoller::DeadLetterQueue do
  subject { LogStash::Instrument::PeriodicPoller::DeadLetterQueue }

  let(:metric) { LogStash::Instrument::Metric.new(LogStash::Instrument::Collector.new) }
  let(:agent) { double("agent")}
  let(:options) { {} }
  subject(:dlq) { described_class.new(metric, agent, options) }

  it "should initialize cleanly" do
    expect { dlq }.not_to raise_error
  end
end
