# encoding: utf-8
require "spec_helper"
require "logstash/plugin"
require "logstash/outputs/base"
require "logstash/codecs/base"
require "logstash/inputs/base"
require "logstash/filters/base"

describe LogStash::Plugin do
  it "should fail lookup on inexisting type" do
    #expect_any_instance_of(Cabin::Channel).to receive(:debug).once
    expect { LogStash::Plugin.lookup("badbadtype", "badname") }.to raise_error(LogStash::PluginLoadingError)
  end

  it "should fail lookup on inexisting name" do
    #expect_any_instance_of(Cabin::Channel).to receive(:debug).once
    expect { LogStash::Plugin.lookup("filter", "badname") }.to raise_error(LogStash::PluginLoadingError)
  end

  it "should fail on bad plugin class" do
    LogStash::Filters::BadSuperClass = Class.new
    expect { LogStash::Plugin.lookup("filter", "bad_super_class") }.to raise_error(LogStash::PluginLoadingError)
  end

  it "should fail on missing config_name method" do
    LogStash::Filters::MissingConfigName = Class.new(LogStash::Filters::Base)
    expect { LogStash::Plugin.lookup("filter", "missing_config_name") }.to raise_error(LogStash::PluginLoadingError)
  end

  it "should lookup an already defined plugin class" do
    class LogStash::Filters::LadyGaga < LogStash::Filters::Base
      config_name "lady_gaga"
    end
    expect(LogStash::Plugin.lookup("filter", "lady_gaga")).to eq(LogStash::Filters::LadyGaga)
  end

  describe "plugin signup in the registry" do

    let(:registry) { LogStash::Registry.instance }

    it "should be present in the registry" do
      class LogStash::Filters::MyPlugin < LogStash::Filters::Base
        config_name "my_plugin"
      end
      path     = "logstash/filters/my_plugin"
      expect(registry.registered?(path)).to eq(true)
    end
  end

  describe "#inspect" do
    class LogStash::Filters::MyTestFilter < LogStash::Filters::Base
      config_name "param1"
      config :num, :validate => :number, :default => 20
      config :str, :validate => :string, :default => "test"
    end
    subject { LogStash::Filters::MyTestFilter.new("num" => 1, "str" => "hello") }

    it "should print the class of the filter" do
      expect(subject.inspect).to match(/^<LogStash::Filters::MyTestFilter/)
    end
    it "should list config options and values" do
      expect(subject.inspect).to match(/num=>1, str=>"hello"/)
    end
  end

  describe "subclass initialize" do
    let(:args) { Hash.new }

    [
      StromaeCodec = Class.new(LogStash::Codecs::Base) do
        config_name "stromae"
        config :foo_tag, :validate => :string, :default => "bar"
      end,
      StromaeFilter = Class.new(LogStash::Filters::Base) do
        config_name "stromae"
        config :foo_tag, :validate => :string, :default => "bar"
      end,
      StromaeInput = Class.new(LogStash::Inputs::Base) do
        config_name "stromae"
        config :foo_tag, :validate => :string, :default => "bar"
      end,
      StromaeOutput = Class.new(LogStash::Outputs::Base) do
        config_name "stromae"
        config :foo_tag, :validate => :string, :default => "bar"
      end
    ].each do |klass|

      it "subclass #{klass.name} does not modify params" do
        klass.new(args)
        expect(args).to be_empty
      end
    end

    context "codec initialization" do

      class LogStash::Codecs::Noop < LogStash::Codecs::Base
        config_name "noop"

        config :format, :validate => :string
        def register; end
      end

      it "should only register once" do
        args   = { "codec" => LogStash::Codecs::Noop.new("format" => ".") }
        expect_any_instance_of(LogStash::Codecs::Noop).to receive(:register).once
        LogStash::Plugin.new(args)
      end

    end
  end

  describe "#id" do
    plugin_types = [
      LogStash::Filters::Base,
      LogStash::Codecs::Base,
      LogStash::Outputs::Base,
      LogStash::Inputs::Base
    ]

    plugin_types.each do |plugin_type|
      let(:plugin) do
        Class.new(plugin_type) do
          config_name "simple_plugin"

          config :host, :validate => :string
          config :export, :validte => :boolean

          def register; end
        end
      end

      let(:config) do
        {
          "host" => "127.0.0.1",
          "export" => true
        }
      end

      subject { plugin.new(config) }

      context "plugin type is #{plugin_type}" do
        context "when there is not ID configured for the output" do
          it "it uses a UUID to identify this plugins" do
            expect(subject.id).not_to eq(nil)
          end

          it "will be different between instance of plugins" do
            expect(subject.id).not_to eq(plugin.new(config).id)
          end
        end

        context "When a user provide an ID for the plugin" do
          let(:id) { "ABC" }
          let(:config) { super.merge("id" => id) }

          it "uses the user provided ID" do
            expect(subject.id).to eq(id)
          end
        end
      end
    end
  end

  describe "#plugin_unique_name" do
    let(:plugin) do
      Class.new(LogStash::Filters::Base,) do
        config_name "simple_plugin"
        config :host, :validate => :string

        def register; end
      end
    end

    let(:config) do
      {
        "host" => "127.0.0.1"
      }
    end

    context "when the id is provided" do
      let(:my_id) { "mysuper-plugin" }
      let(:config) { super.merge({ "id" => my_id })}
      subject { plugin.new(config) }

      it "return a human readable ID" do
        expect(subject.plugin_unique_name).to eq("simple_plugin_#{my_id}")
      end
    end

    context "when the id is not provided provided" do
      subject { plugin.new(config) }

      it "return a human readable ID" do
        expect(subject.plugin_unique_name).to match(/^simple_plugin_/)
      end
    end
  end


  context "When the plugin record a metric" do
    let(:config) { {} }

    [LogStash::Inputs::Base, LogStash::Filters::Base, LogStash::Outputs::Base].each do |base|
      let(:plugin) do
        Class.new(base) do
          config_name "testing"

          def register
            metric.gauge("power_level", 9000)
          end
        end
      end

      subject { plugin.new(config) } 

      context "when no metric is set to the plugin" do
        context "when `enable_metric` is TRUE" do
          it "recording metric should not raise an exception" do
            expect { subject.register }.not_to raise_error
          end

          it "should use a `NullMetric`" do
            expect(subject.metric).to be_kind_of(LogStash::Instrument::NullMetric)
          end
        end

        context "when `enable_metric` is FALSE" do
          let(:config) { { "enable_metric" => false } }

          it "recording metric should not raise an exception" do
            expect { subject.register }.not_to raise_error
          end

          it "should use a `NullMetric`" do
            expect(subject.metric).to be_kind_of(LogStash::Instrument::NullMetric)
          end
        end
      end

      context "When a specific metric collector is configured" do
        context "when `enable_metric` is TRUE" do
          let(:metric) { LogStash::Instrument::Metric.new(LogStash::Instrument::Collector.new).namespace("dbz") }

          before :each do
            subject.metric = metric
          end

          it "recording metric should not raise an exception" do
            expect { subject.register }.not_to raise_error
          end

          it "should use the configured metric" do
            expect(subject.metric).to eq(metric)
          end
        end

        context "when `enable_metric` is FALSE" do
          let(:config) { { "enable_metric" => false } }

          it "recording metric should not raise an exception" do
            expect { subject.register }.not_to raise_error
          end

          it "should use a `NullMetric`" do
            expect(subject.metric).to be_kind_of(LogStash::Instrument::NullMetric)
          end
        end
      end
    end
  end
end
