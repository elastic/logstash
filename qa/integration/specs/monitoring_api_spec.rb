require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'
require "logstash/devutils/rspec/spec_helper"
require "stud/try"

describe "Test Monitoring API" do
  before(:all) {
    @fixture = Fixture.new(__FILE__)
  }

  after(:all) {
    @fixture.teardown
  }
  
  after(:each) {
    @fixture.get_service("logstash").teardown
  }
  
  let(:number_of_events) { 5 }
  let(:max_retry) { 120 }

  it "can retrieve event stats" do
    logstash_service = @fixture.get_service("logstash")
    logstash_service.start_with_stdin
    logstash_service.wait_for_logstash
    number_of_events.times { logstash_service.write_to_stdin("Hello world") }

    Stud.try(max_retry.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
      # event_stats can fail if the stats subsystem isn't ready
      result = logstash_service.monitoring_api.event_stats rescue nil
      expect(result).not_to be_nil
      expect(result["in"]).to eq(number_of_events)
    end
  end

  it "can retrieve JVM stats" do
    logstash_service = @fixture.get_service("logstash")
    logstash_service.start_with_stdin
    logstash_service.wait_for_logstash

    Stud.try(max_retry.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
      # node_stats can fail if the stats subsystem isn't ready
      result = logstash_service.monitoring_api.node_stats rescue nil
      expect(result).not_to be_nil
      expect(result["jvm"]).not_to be_nil
      expect(result["jvm"]["uptime_in_millis"]).to be > 100
    end
  end

  it 'can retrieve dlq stats' do
    logstash_service = @fixture.get_service("logstash")
    logstash_service.start_with_stdin
    logstash_service.wait_for_logstash
    Stud.try(max_retry.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
      # node_stats can fail if the stats subsystem isn't ready
      result = logstash_service.monitoring_api.node_stats rescue nil
      expect(result).not_to be_nil
      # we use fetch here since we want failed fetches to raise an exception
      # and trigger the retry block
      queue_stats = result.fetch('pipelines').fetch('main')['dead_letter_queue']
      if logstash_service.settings.get("dead_letter_queue.enable")
        expect(queue_stats['queue_size_in_bytes']).not_to be_nil
      else
        expect(queue_stats).to be nil
      end
    end
  end

  it "can retrieve queue stats" do
    logstash_service = @fixture.get_service("logstash")
    logstash_service.start_with_stdin
    logstash_service.wait_for_logstash

    Stud.try(max_retry.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
      # node_stats can fail if the stats subsystem isn't ready
      result = logstash_service.monitoring_api.node_stats rescue nil
      expect(result).not_to be_nil
      # we use fetch here since we want failed fetches to raise an exception
      # and trigger the retry block
      queue_stats = result.fetch("pipelines").fetch("main").fetch("queue")
      expect(queue_stats).not_to be_nil
      if logstash_service.settings.feature_flag == "persistent_queues"
        expect(queue_stats["type"]).to eq "persisted"
        queue_data_stats = queue_stats.fetch("data")
        expect(queue_data_stats["free_space_in_bytes"]).not_to be_nil
        expect(queue_data_stats["storage_type"]).not_to be_nil
        expect(queue_data_stats["path"]).not_to be_nil
        expect(queue_stats["events"]).not_to be_nil
        queue_capacity_stats = queue_stats.fetch("capacity")
        expect(queue_capacity_stats["page_capacity_in_bytes"]).not_to be_nil
        expect(queue_capacity_stats["max_queue_size_in_bytes"]).not_to be_nil
        expect(queue_capacity_stats["max_unread_events"]).not_to be_nil
      else
        expect(queue_stats["type"]).to eq("memory")
      end
    end
  end
end
