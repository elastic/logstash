# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "stud/task"

# Settings' TimeValue is using nanos seconds as the default unit
def time_value(time)
  LogStash::Util::TimeValue.from_value(time).to_nanos
end

# Allow to easily asserts the configuration created
# by the `#additionals_settings` callback
def define_settings(settings_options)
  settings_options.each do |name, options|
    klass, expected_default_value = options

    it "define setting: `#{name} of type: `#{klass}` with a default value of `#{expected_default_value}`" do
      expect { settings.get_setting(name) }.not_to raise_error
      expect(settings.get_setting(name)).to be_kind_of(klass)
      expect(settings.get_default(name)).to eq(expected_default_value)
    end
  end
end

def apply_settings(settings_values, settings = nil)
  settings = settings.nil? ? LogStash::SETTINGS.clone : settings

  settings_values.each do |key, value|
    settings.set(key, value)
  end

  return yield(settings) if block_given?

  settings
end

##
# yields to the provided block with the ENV modified by
# the provided overrides. Values given as `nil` will be deleted
# if present in the base ENV.
#
# @param replacement [Hash{String=>[String,nil]}]
def with_environment(overrides)
  replacement = ENV.to_hash
                   .merge(overrides)
                   .reject { |_, v| v.nil? }

  with_environment!(replacement) { yield }
end

##
# yields to the provided block with the ENV replaced
# @param replacement [Hash{String=>String}]
def with_environment!(replacement)
  original = ENV.to_hash.dup.freeze
  ENV.replace(replacement)

  yield
ensure
  ENV.replace(original)
end

def start_agent(agent)
  agent_task = Stud::Task.new do
    begin
      agent.execute
    rescue => e
      raise "Start Agent exception: #{e}"
    end
  end

  wait(30).for { agent.running? }.to be(true)
  agent_task
end

module LogStash
  module Inputs
    class DummyBlockingInput < LogStash::Inputs::Base
      config_name "dummyblockinginput"
      milestone 2

      def register
      end

      def run(_)
        sleep(1) while !stop?
      end

      def stop
      end
    end
  end
end

def cluster_info(version = LOGSTASH_VERSION, build_flavour = "default")
  {"name" => "MacBook-Pro",
   "cluster_name" => "elasticsearch",
   "cluster_uuid" => "YgpKq8VkTJuGTSb9aidlIA",
   "version" =>
     {"number" => "#{version}",
      "build_flavor" => "#{build_flavour}",
      "build_type" => "tar",
      "build_hash" => "26eb422dc55236a1c5625e8a73e5d866e54610a2",
      "build_date" => "2020-09-24T09:37:06.459350Z",
      "build_snapshot" => true,
      "lucene_version" => "8.7.0",
      "minimum_wire_compatibility_version" => "7.17.0",
      "minimum_index_compatibility_version" => "7.0.0"},
   "tagline" => "You Know, for Search"}
end
