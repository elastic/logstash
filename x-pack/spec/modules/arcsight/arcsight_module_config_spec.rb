require_relative '../../../../x-pack/lib/x-pack/logstash_registry.rb'
require 'logstash-core'
require 'logstash/settings'
require 'logstash/util/modules_setting_array'
require 'logstash/modules/scaffold'
require 'arcsight_module_config_helper'

describe "ArcSight module" do
  let(:logstash_config_class) { LogStash::Modules::LogStashConfig  }
  let(:module_name) { "arcsight" }
  let(:module_path) { ::File.join(LogStash::Environment::LOGSTASH_HOME, "x-pack", "modules", module_name, "configuration") }
  let(:mod) { instance_double("arcsight", :directory => module_path, :module_name => module_name) }
  let(:settings) { {} }
  subject { logstash_config_class.new(mod, settings) }

  it "test" do
    expect(subject.config_string).to include("index => \"arcsight-#{::LOGSTASH_VERSION}-%{+YYYY.MM.dd}\"")
  end
end
