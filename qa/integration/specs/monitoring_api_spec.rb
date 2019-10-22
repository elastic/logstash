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

  it "can retrieve dlq stats" do
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

  it "can configure logging" do
    logstash_service = @fixture.get_service("logstash")
    logstash_service.start_with_stdin
    logstash_service.wait_for_logstash

    Stud.try(max_retry.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
      # monitoring api can fail if the subsystem isn't ready
      result = logstash_service.monitoring_api.logging_get rescue nil
      expect(result).not_to be_nil
      expect(result["loggers"].size).to be > 0
      #default
      logging_get_assert logstash_service, "INFO", "TRACE"

      #root logger - does not apply to logger.slowlog
      logging_put_assert logstash_service.monitoring_api.logging_put({"logger." => "WARN"})
      logging_get_assert logstash_service, "WARN", "TRACE"
      logging_put_assert logstash_service.monitoring_api.logging_put({"logger." => "INFO"})
      logging_get_assert logstash_service, "INFO", "TRACE"

      #package logger
      logging_put_assert logstash_service.monitoring_api.logging_put({"logger.logstash.agent" => "DEBUG"})
      expect(logstash_service.monitoring_api.logging_get["loggers"]["logstash.agent"]).to eq ("DEBUG")
      logging_put_assert logstash_service.monitoring_api.logging_put({"logger.logstash.agent" => "INFO"})
      logging_get_assert logstash_service, "INFO", "TRACE"

      #parent package loggers
      logging_put_assert logstash_service.monitoring_api.logging_put({"logger.logstash" => "ERROR"})
      logging_put_assert logstash_service.monitoring_api.logging_put({"logger.slowlog" => "ERROR"})

      result = logstash_service.monitoring_api.logging_get
      result["loggers"].each do | k, v |
        #since we explicitly set the logstash.agent logger above, the logger.logstash parent logger will not take precedence
        if !k.eql?("logstash.agent") && (k.start_with?("logstash") || k.start_with?("slowlog"))
          expect(v).to eq("ERROR")
        else
          expect(v).to eq("INFO")
        end
      end

      # all log levels should be reset to original values
      logging_put_assert logstash_service.monitoring_api.logging_reset
      logging_get_assert logstash_service, "INFO", "TRACE"
    end
  end

  it "can retrieve pipeline metrics stats - config string" do
    logstash_service = @fixture.get_service("logstash")
    logstash_service.start_with_stdin
    logstash_service.wait_for_logstash

    Stud.try(max_retry.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
      # event_stats can fail if the stats subsystem isn't ready
      result = logstash_service.monitoring_api.pipeline_stats("main") rescue nil
      puts "<><><> #{result} <><><>"
      expect(result).not_to be_nil

      # we use fetch here since we want failed fetches to raise an exception
      # and trigger the retry block
       inputs_stats = result.fetch("plugins").fetch("inputs")[0]
       config_ref = inputs_stats.fetch("config-ref")
       puts ">>> inputs_stats: #{inputs_stats} <<<"
       expect(config_ref).to eq("S: config_string, L:1, C:8")
    end
  end

  describe "multifile pipelines" do

    let!(:settings_dir) { Stud::Temporary.directory("logstash-splitted-pipeline-config-test") }

    it "can retrieve pipeline metrics stats - multiple files" do
      IO.write(settings_dir + "/pipeline_1_piece.conf", """
      input {
      	stdin {
      	  codec => json {
      	    charset => \"UTF-8\"
      	  }
      	}
      }

      filter {
      	sleep {
      		time => 1
      	}
      }
      """)

      IO.write(settings_dir + "/pipeline_2_piece.conf", """
      output {
       	stdout {
       	  codec => rubydebug
       	}
      }
      """)

      logstash_service = @fixture.get_service("logstash")
      logstash_service.spawn_logstash("--path.config", settings_dir)
      logstash_service.wait_for_logstash

      Stud.try(max_retry.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
        # event_stats can fail if the stats subsystem isn't ready
        result = logstash_service.monitoring_api.pipeline_stats("main") rescue nil
        expect(result).not_to be_nil

        inputs_stats = result.fetch("plugins").fetch("inputs")[0]
        config_ref = inputs_stats.fetch("config-ref")
        expect_source_ref(config_ref, "pipeline_1_piece.conf", 3, 8)

        input_codec_stats = result.fetch("plugins").fetch("codecs").select { |c| c["name"] == "json"}.first
        expect(input_codec_stats).not_to be_nil
        config_ref = input_codec_stats.fetch("config-ref")
        expect_source_ref(config_ref, "pipeline_1_piece.conf", 3, 0)

        filters_stats = result.fetch("plugins").fetch("filters")[0]
        config_ref = filters_stats.fetch("config-ref")
        expect_source_ref(config_ref, "pipeline_1_piece.conf", 11, 8)

        outputs_stats = result.fetch("plugins").fetch("outputs")[0]
        config_ref = outputs_stats.fetch("config-ref")
        expect_source_ref(config_ref, "pipeline_2_piece.conf", 3, 9)

        output_codec_stats = result.fetch("plugins").fetch("codecs").select { |c| c["name"] == "rubydebug"}.first
        expect(output_codec_stats).not_to be_nil
        config_ref = output_codec_stats.fetch("parent-config-ref")
        expect_source_ref(config_ref, "pipeline_2_piece.conf", 3, 9)
      end
    end
  end

  private

  def logging_get_assert(logstash_service, logstash_level, slowlog_level)
    result = logstash_service.monitoring_api.logging_get
    result["loggers"].each do | k, v |
      if k.start_with? "logstash", "org.logstash" #logstash is the ruby namespace, and org.logstash for java
        expect(v).to eq(logstash_level)
      elsif k.start_with? "slowlog"
        expect(v).to eq(slowlog_level)
      end
    end
  end

  def logging_put_assert(result)
    expect(result["acknowledged"]).to be(true)
  end

  def expect_source_ref(config_ref, filename, expected_line, expected_column)
    expect(config_ref).to match("S: \/tmp\/logstash-splitted-pipeline-config-test.*\/#{filename}, L:#{expected_line}, C:#{expected_column}")
  end

end
